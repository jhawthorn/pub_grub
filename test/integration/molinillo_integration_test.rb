require 'test_helper'
require 'json'

class MolinilloIntegrationTest < Minitest::Test
  BASE_DIR = File.expand_path('../fixtures/molinillo_integration_specs', __dir__)
  CASES_DIR = "#{BASE_DIR}/case"
  INDEX_DIR = "#{BASE_DIR}/index"

  def clean_deps(requested, base=[])
    deps = {}

    add_dep = -> (name, requirements) {
      name = name.delete("\x01")
      deps[name] ||= []
      deps[name].concat requirements.split(",")
    }

    requested.each do |name, requirements|
      add_dep[name, requirements]
    end

    base.each do |dep|
      add_dep[dep['name'], dep['version']]
    end

    deps
  end

  def flatten_deps(deps)
    hash = {}
    deps.each do |dep|
      hash[dep['name']] = dep['version']
      hash.update(flatten_deps(dep['dependencies']))
    end
    hash
  end

  molinillo_cases = Dir[File.join(CASES_DIR, '*.json')].sort

  if molinillo_cases.empty?
    warn "Didn't find any molinillo test cases. You might need to run: git submodule update --init"
  end

  molinillo_cases.each do |case_file|
    case_data = JSON.parse(File.read(case_file))

    define_method "test_#{case_data["name"]}" do
      return if case_data["name"].include?("circular")

      index_name = case_data["index"] || "awesome"

      index_data = JSON.parse(File.read(File.join(INDEX_DIR, "#{index_name}.json")))

      source = PubGrub::StaticPackageSource.new do |s|
        index_data.each do |package_name, packages|
          packages.sort_by do |package|
            version = Gem::Version.new(package['version'])
            [
              (version.prerelease? ? 0 : 1),
              version
            ]
          end.reverse.each do |package|
            s.add package_name, package['version'], deps: clean_deps(package['dependencies'])
          end
        end

        s.root deps: clean_deps(case_data['requested'], case_data['base'])
      end

      solver = PubGrub::VersionSolver.new(source: source)

      if case_data['conflicts'].empty?
        result = solver.solve

        assert_solution source, result, flatten_deps(case_data['resolved'])
      else
        ex = assert_raises PubGrub::SolveFailure do
          solver.solve
        end

        message = ex.to_s
        case_data['conflicts'].each do |conflict|
          assert_includes message, conflict
        end
      end
    end
  end
end

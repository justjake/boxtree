# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Safe git_ls_files
def git_ls_files(path)
  operation = "git -C #{path} ls-files -z"
  files = `#{operation}`.split("\x0")
  raise "Failed optation #{operation.inspect}" unless $?.success?
  files
end

Gem::Specification.new do |spec|
  spec.name          = "boxtree"
  spec.version       = '0.0.1'
  spec.authors       = ["Jake Teton-Landis"]
  spec.email         = ["jake.tl@airbnb.com"]

  spec.summary       = %q{View drawing library based on yoga_layout}
  spec.homepage      = "https://github.com/justjake/boxtree"

  spec.files         = [
    # All the files tracked in git, except for tests.
    *git_ls_files('.').reject { |f| f.match(%r{^(test|spec|features)/}) },
  ]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'yoga_layout'
  spec.add_development_dependency "bundler", "~> 1.15"
end

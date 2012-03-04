require 'bundler/gem_tasks'

# Adapted from matthewtodd's shoe gem at https://github.com/matthewtodd/shoe
desc "Runs all tests for the gem"
task :test do
  spec = Gem::Specification.load(Dir.glob('*.gemspec')[0])
  system('testrb', *spec.test_files) || exit(1)
end

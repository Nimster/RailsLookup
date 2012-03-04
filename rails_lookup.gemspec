# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rails_lookup/version"

Gem::Specification.new do |s|
  s.name        = %q{rails_lookup}
  s.version     = RailsLookup::VERSION
  s.authors     = ["Nimrod Priell"]
  s.email       = ["nimrod.priell@gmail.com"]
  s.homepage    = %q{http://github.com/Nimster/RailsLookup/}
  s.summary     = %q{Lookup table macro for ActiveRecords. See more in the README}

  s.rubyforge_project = %q{rails_lookup}

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.date = %q{2011-08-09}
  s.description = %q{Lookup tables with ruby-on-rails}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*_test.rb`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [%q{README}, %q{lib/rails_lookup.rb}]
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{rails_lookup}, %q{--main}, %q{README}]

  s.add_dependency 'rails', '3.0.9'
  s.add_development_dependency 'sqlite3'
end

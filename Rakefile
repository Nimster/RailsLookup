require 'rubygems'  
require 'rake'  
require 'echoe'  
  
Echoe.new('rails_lookup', '0.0.3') do |s|  
  s.description = File.read(File.join(File.dirname(__FILE__), 'README')) 
  s.summary     = "Lookup table macro for ActiveRecords" 
  s.url             = "http://github.com/Nimster/RailsLookup/"
  s.author      = "Nimrod Priell"
  s.email       = "@nimrodpriell" #Twitter
  s.ignore_pattern  = ["tmp/*", "script/*", "Manifest"]  
  s.development_dependencies = []  
end  
  
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }  
=begin
spec = Gem::Specification.new do |s|
  s.name        = "rails_lookup"
  s.requirements = [ 'Rails >= 3.0.7, Ruby >= 1.9.1' ]
  s.version     = "0.0.1"
  s.homepage    = ""
  s.platform    = "Gem::Platform::RUBY"
  s.required_ruby_version = '>=1.9' 
  s.files = Dir['**/**'] 
  s.executables = [] 
  s.test_files = [] #Dir["test/test*.rb"] 
  s.has_rdoc = false
end 
=end

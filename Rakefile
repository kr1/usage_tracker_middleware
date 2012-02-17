# encoding: utf-8 
#
require 'rake'
require 'rdoc/task'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'panmind-usage-tracker-middleware'
    gemspec.summary     = 'a rack middleware that helps to tracks usage' 
    gemspec.description = 'This software collects usage information of ' \
                          'a rack-application, assembles a json object ' \
                          'and sends this object via UDP to a specified server'
    gemspec.authors     = ['Christian Woerner', 'Fabrizio Regini', 'Marcello Barnaba']
    gemspec.homepage    = 'http://github.com/Panmind/usage_tracker_middleware'
    gemspec.email       = 'info@panmind.com'
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

desc 'Generate the rdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.add %w( README.md lib/**/*.rb )

  rdoc.main  = 'README.md'
  rdoc.title = 'Rails Application Usage Tracker Middleware'
end

require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "tcl"
    gem.summary = %Q{Tcl bindings for Ruby}
    gem.description = %Q{A minimal Ruby interface to libtcl}
    gem.email = "sstephenson@gmail.com"
    gem.homepage = "http://github.com/sstephenson/ruby-tcl"
    gem.authors = ["Sam Stephenson"]

    gem.extensions = FileList['ext/tcl_ruby/extconf.rb']
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => [:check_dependencies, :compile]

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tcl #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/extensiontask'
Rake::ExtensionTask.new("tcl_ruby")
CLEAN.include ['**/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log}']

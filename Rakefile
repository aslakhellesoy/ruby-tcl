require "rake/testtask"
require "rcov/rcovtask"

task :default => "test"
task :test => "test:units"

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/**/*_test.rb"]
    t.verbose = true
  end

  Rcov::RcovTask.new(:coverage) do |t|
    t.test_files = FileList["test/**/*_test.rb"]
    t.verbose = true
    t.rcov_opts << "-x 'rcov\.rb$'"
  end
end

require "rubygems"
require "rake/testtask"
require "rake/rdoctask"
require "jeweler"

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "mailbox"
  gemspec.summary = "Mailbox is a JRuby module that simplifies concurrency and is backed by JVM threads."
  gemspec.description = gemspec.summary
  gemspec.email = "asher.friedman@gmail.com"
  gemspec.homepage = "http://joelash.github.com/mailbox"
  gemspec.authors = ["Joel Friedman", "Patrick Farley"]
  #	gemspec.requirements << 'jretlang'
  #	gemspec.add_dependency "jrlbm"

  gemspec.rubyforge_project = "mailbox"
end

Jeweler::RubyforgeTasks.new do |rubyforge|
  rubyforge.doc_task = "rdoc"
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "lib/**/*.rb")
  rdoc.rdoc_dir = "rdoc"
end


require "rubygems"
require "rake/testtask"
require "rake/rdoctask"
require "jeweler"

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = true
end

Rake::TestTask.new("example") do |t|
  t.libs << "example"
  t.test_files = FileList['example/**/*_example.rb']
  t.verbose = true
  t.warning = true
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "mailbox"
  gemspec.summary = "Mailbox is a JRuby module that simplifies concurrency and is backed by JVM threads."
  gemspec.description = gemspec.summary
  gemspec.email = "asher.friedman@gmail.com"
  gemspec.homepage = "http://joelash.github.com/mailbox"
  gemspec.authors = ["Joel Friedman", "Patrick Farley"]

  gemspec.add_dependency "jretlang"

  gemspec.add_development_dependency "jeweler"

  gemspec.rubyforge_project = "mailbox"
end

Jeweler::GemcutterTasks.new

Jeweler::RubyforgeTasks.new do |rubyforge|
  rubyforge.doc_task = "rdoc"
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = "README"
  rdoc.rdoc_files.include("README", "lib/**/*.rb")
  rdoc.rdoc_dir = "rdoc"
end


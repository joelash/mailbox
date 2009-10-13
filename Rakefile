require "rubygems"
require "rake/testtask"
require "jeweler"

task :default => :test

Rake::TestTask.new do |t|
	t.libs << "test"
	t.test_files = FileList['test/**/*_test.rb']
	t.verbose = true
end

Jeweler::Tasks.new do |gemspec|
	gemspec.name = "mailbox"
	gemspec.summary = "Mailbox is a JRuby module that simplifies the concurrenct and is backed by JVM threads."
	gemspec.description = "Mailbox is a JRuby module that simplifies the concurrenct and is backed by JVM threads."
	gemspec.email = "asher.friedman@gmail.com"
	gemspec.homepage = "http://joelash.github.com/mailbox"
	gemspec.authors = ["Joel Friedman", "Patrick Farley"]
end


# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mailbox}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joel Friedman", "Patrick Farley"]
  s.date = %q{2010-04-21}
  s.description = %q{Mailbox is a JRuby module that simplifies concurrency and is backed by JVM threads.}
  s.email = %q{asher.friedman@gmail.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "README",
     "Rakefile",
     "VERSION.yml",
     "example/channel_based_log_example.rb",
     "example/i_can_has_cheese_burger_example.rb",
     "example/log_example.rb",
     "example/parallel_each_example.rb",
     "example/ping_pong_example.rb",
     "lib/mailbox.rb",
     "lib/synchronized.rb",
     "mailbox.gemspec",
     "mailbox.iml",
     "mailbox.ipr",
     "test/mailbox_test.rb",
     "test/synchronized_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://joelash.github.com/mailbox}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mailbox}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Mailbox is a JRuby module that simplifies concurrency and is backed by JVM threads.}
  s.test_files = [
    "test/mailbox_test.rb",
     "test/synchronized_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jretlang>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<jretlang>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<jretlang>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end


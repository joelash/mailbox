require 'java'

Dir[File.join(File.dirname(__FILE__), 'mailbox', '**', '*.rb')].sort.each { |f| require f }

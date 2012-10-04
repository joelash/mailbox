require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mailbox'

module Mailbox
  module ObjectExtensions
    def dbg_msg label, x, location
      "#{label} from #{location}:\n #{x.respond_to?(:pretty_inspect) ? x.pretty_inspect : x.inspect}"
    end

    def dbg_type x
      dbg x.class.name, "type of #{x}", caller[0]
      x
    end

    def dbg_puts x
      puts x
      x
    end

    def dbg x, label = 'value', context = nil
      context ||= caller[0]
      puts dbg_msg(label, x, context)
      x
    end

    def dbgv x, label = 'value'
      dbg x, "*********************************** #{label}"
    end

  end
end

class Object
  include Mailbox::ObjectExtensions
end

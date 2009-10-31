require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

class DataProcessor
  include Mailbox

  mailslot
  def process(data)
    p "#{data} was processed by Thread# #{Thread.current.object_id}"
  end

end

class ParallelEachExample < Test::Unit::TestCase

  def test_a_simple_parallel_each

    items = ["item1", "item2", "item3", "item4", "item5"]
    processors = [DataProcessor.new, DataProcessor.new, DataProcessor.new]

    items.each_with_index do |item, index|
      processors[index % processors.length].process item
    end

  end

end
require 'test_helper.rb'

class SynchronizedTest < Test::Unit::TestCase
  
  def test_supports_synchronized_access_of_methods_by_including_synchronized

    klass = Class.new do
      include Synchronized

      attr_accessor :values

      def initialize
        @values = []
      end

      synchronized
      def test_method( value )
        @value = value
        @values << @value
        sleep 1
        @values << @value
      end
    end

    clazz = klass.new

    thread_1 = Thread.new do
      clazz.test_method "thread 1"
    end

    sleep 0.3

    thread_2 = Thread.new do
      clazz.test_method "thread 2"
    end

    thread_1.join 1
    thread_2.join 1

    assert_equal "thread 1", clazz.values[0], "1st wrong"
    assert_equal "thread 1", clazz.values[1], "2nd wrong"
    assert_equal "thread 2", clazz.values[2], "3rd wrong"
    assert_equal "thread 2", clazz.values[3], "4th wrong"
    
  end
  
  def test_supports_synchronized_access_of_methods_by_including_mailbox

    klass = Class.new do
      include Mailbox

      attr_accessor :values

      def initialize
        @values = []
      end

      synchronized
      def test_method( value )
        @value = value
        @values << @value
        sleep 1
        @values << @value
      end
    end

    clazz = klass.new

    thread_1 = Thread.new do
      clazz.test_method "thread 1"
    end

    sleep 0.3

    thread_2 = Thread.new do
      clazz.test_method "thread 2"
    end

    thread_1.join 1
    thread_2.join 1

    assert_equal "thread 1", clazz.values[0], "1st wrong"
    assert_equal "thread 1", clazz.values[1], "2nd wrong"
    assert_equal "thread 2", clazz.values[2], "3rd wrong"
    assert_equal "thread 2", clazz.values[3], "4th wrong"
    
  end
end
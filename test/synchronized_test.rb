require File.dirname(__FILE__) + '/test_helper.rb'

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

  def test_support_reentrant_synchronized_access
    klass = Class.new do
      include Mailbox

      synchronized
      def test_method_one
        test_method_two
      end

      synchronized
      def test_method_two
        true
      end
    end

    clazz = klass.new
    assert clazz.test_method_one
  end
end

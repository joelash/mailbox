require File.expand_path '../../spec_helper', __FILE__

module Mailbox
  describe Core do
    context '#is_mailslot?' do
      klass = Class.new do
        include Mailbox::Core

        class << self
          def self_less_than_mailslot; end
          private
          def self_less_than_not_mailslot; end
        end

        def self.self_dot_mailslot; end
        def this_is_mailslot; end

        private
        def this_is_not_mailslot; end
      end

      context 'for instance methods' do
        before { @instance = klass.new }

        it 'returns true for public methods' do
          @instance.is_mailslot?(:this_is_mailslot).should be_true
        end

        it 'returns false for private methods' do
          @instance.is_mailslot?(:this_is_not_mailslot).should be_false
        end
      end

      context 'for class methods' do
        context 'in class << self block' do
          it 'returns true for public' do
            klass.is_mailslot?(:self_less_than_mailslot).should be_true
          end

          it 'returns true for public' do
            klass.is_mailslot?(:self_less_than_not_mailslot).should be_false
          end
        end

        it 'returns true when defined with self.' do
          klass.is_mailslot?(:self_dot_mailslot).should be_true
        end
      end
    end

  end
end

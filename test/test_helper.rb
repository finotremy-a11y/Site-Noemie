ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Minimal stub helper when Object#stub is unavailable in this runtime.
class Object
  unless method_defined?(:stub)
    def stub(method_name, value = nil, &block)
      singleton_class = class << self; self; end
      had_original = respond_to?(method_name, true)
      original_method = method(method_name) if had_original

      singleton_class.send(:define_method, method_name) do |*args, **kwargs, &mblock|
        if value.respond_to?(:call)
          value.call(*args, **kwargs, &mblock)
        else
          value
        end
      end

      block.call
    ensure
      singleton_class.send(:remove_method, method_name) rescue nil
      singleton_class.send(:define_method, method_name, original_method) if had_original
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

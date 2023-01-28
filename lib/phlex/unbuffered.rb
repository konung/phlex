# frozen_string_literal: true

module Phlex
	class Unbuffered < BasicObject
		CACHE = ::Concurrent::Map.new

		def self.call(object)
			decorator = CACHE.compute_if_absent(object.class.name) { ::Class.new(self) }
			decorator.new(object)
		end

		def initialize(object)
			@object = object
		end

		def inspect
			"Unbuffered(#{@object.class.name})[object: #{@object.inspect}]"
		end

		# Borrow some important methods from Object
		define_method :__class__,
			::Object.instance_method(:class)

		define_method :__public_send__,
			::Object.instance_method(:public_send)

		define_method :__callee__,
			::Object.instance_method(:__callee__)

		def respond_to_missing?(...)
			@object.respond_to?(...)
		end

		def method_missing(name, *args, **kwargs, &block)
			if @object.respond_to?(name)

				__class__.define_method(name) do |*a, **k, &b|
					@object.capture { @object.public_send(name, *a, **k, &b) }
				end

				# Now we've defined this missing method, we can call it.
				__public_send__(name, *args, &block)
			else
				super
			end
		end

		# Forward some methods to the original underlying method
		def call(...)
			@object.call(...)
		end

		def send(...)
			@object.send(...)
		end

		def public_send(...)
			@object.public_send(...)
		end
	end
end
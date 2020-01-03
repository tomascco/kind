# frozen_string_literal: true

require 'kind/version'

module Kind
  class Error < TypeError
    def initialize(klass, object)
      super("#{object.inspect} expected to be a kind of #{klass}")
    end
  end

  module Is
    def self.call(expected, value)
      expected_mod = Kind.of.Module(expected)
      mod = Kind.of.Module(value)

      mod <= expected_mod || false
    end

    def self.Class(value)
      value.is_a?(::Class)
    end

    def self.Module(value)
      value == Module || (value.is_a?(::Module) && !self.Class(value))
    end
  end

  class Checker
    attr_reader :type

    def initialize(type)
      @type = type
    end

    def class?(value)
      Kind::Is.call(@type, value)
    end

    def instance?(value)
      value.is_a?(@type)
    end

    def or_nil(value)
      return value if instance?(value)
    end
  end

  module Of
    def self.call(klass, object)
      return object if object.is_a?(klass)

      raise Kind::Error.new(klass, object)
    end

    def self.Class(object)
      self.call(::Class, object)
    end

    def self.Module(object)
      self.call(::Module, object)
    end
  end

  module Types
    extend self

    KIND_OF = <<-RUBY
      def self.%{name}(object = nil)
        return Kind::Of::%{name} if object.nil?

        Kind::Of.call(::%{name}, object)
      end
    RUBY

    KIND_IS = <<-RUBY
      def self.%{name}(value)
        Kind::Is.call(::%{name}, value)
      end
    RUBY

    private_constant :KIND_OF, :KIND_IS

    def add(mod)
      name = Kind.of.Module(mod).name

      unless Of.respond_to?(name)
        Of.instance_eval(KIND_OF % { name: name })
        Of.const_set(name, Checker.new(mod).freeze)
      end

      Is.instance_eval(KIND_IS % { name: name }) unless Is.respond_to?(name)
    end
  end

  def self.is; Is; end
  def self.of; Of; end

  # Classes
  [
    String, Symbol, Numeric, Integer, Float, Regexp, Time,
    Array, Range, Hash, Struct, Enumerator,
    Method, Proc,
    IO, File
  ].each { |klass| Types.add(klass) }

  # Modules
  [
    Enumerable, Comparable
  ].each { |klass| Types.add(klass) }

  # ---------------------- #
  # Special types checkers #
  # ---------------------- #
  module Is
    def self.Boolean(value)
      klass = Kind.of.Class(value)
      klass <= TrueClass || klass <= FalseClass
    end
  end

  module Of
    # -- Boolean

    def self.Boolean(object = nil)
      return Kind::Of::Boolean if object.nil?

      return object if object.is_a?(::TrueClass) || object.is_a?(::FalseClass)

      raise Kind::Error.new('Boolean'.freeze, object)
    end

    const_set(:Boolean, Class.new(Checker) do
      def class?(value)
        Kind.is.Boolean(value)
      end

      def instance?(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end
    end.new([TrueClass, FalseClass].freeze).freeze)

    # -- Lambda

    def self.Lambda(object = nil)
      return Kind::Of::Lambda if object.nil?

      return object if object.is_a?(::Proc) && object.lambda?

      raise Kind::Error.new('Lambda'.freeze, object)
    end

    const_set(:Lambda, Class.new(Checker) do
      def instance?(value)
        value.is_a?(::Proc) && value.lambda?
      end
    end.new(::Proc).freeze)
  end

  private_constant :Checker
end

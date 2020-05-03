# frozen_string_literal: true

module Kind
  module Checkable
    def class?(value)
      Kind::Is.__call__(__kind, value)
    end

    def instance(value, options = Empty::HASH)
      default = options[:or]

      return Kind::Of.(__kind, value) if ::Kind::Maybe::Value.none?(default)

      instance?(value) ? value : Kind::Of.(__kind, default)
    end

    def [](value, options = options = Empty::HASH)
      instance(value, options)
    end

    def instance?(value)
      value.is_a?(__kind)
    end

    def or_nil(value)
      return value if instance?(value)
    end

    def or_undefined(value)
      or_nil(value) || Kind::Undefined
    end

    def as_maybe(value = Kind::Undefined)
      return __as_maybe__(value) if value != Kind::Undefined

      as_maybe_to_proc
    end

    def as_optional(value = Kind::Undefined)
      as_maybe(value)
    end

    def __as_maybe__(value)
      Kind::Maybe.new(or_nil(value))
    end

    def as_maybe_to_proc
      @as_maybe_to_proc ||=
        -> checker { -> value { checker.__as_maybe__(value) } }.call(self)
    end
  end

  private_constant :Checkable

  class Checker
    include Checkable

    attr_reader :__kind

    def initialize(kind)
      @__kind = kind
    end
  end
end

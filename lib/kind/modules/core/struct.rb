# frozen_string_literal: true

module Kind
  module Struct
    extend self, TypeChecker

    def kind; ::Struct; end
  end

  def self.Struct?(*values)
    KIND.of?(::Struct, values)
  end
end

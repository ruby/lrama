module Lrama
  class Lexer
    class Token
      class InstantiateRule < Token
        class Arguments
          attr_reader :values, :count

          def initialize(values)
            @values = values
            @count = values.count
          end

          def to_s
            values.map(&:s_value).join('_')
          end

          def [](index)
            values[index]
          end

          def first
            values.first
          end

          def actual_values(actual_args, parameters)
            actual = values.map do |v|
              i = parameters.index { |param| param.s_value == v.s_value }
              i.nil? ? v : actual_args[i]
            end
            Arguments.new(actual)
          end

          def replace_token(parameters, token, replaced)
            values.map do |v|
              i = parameters.index { |param| param.s_value == v.s_value }
              i.nil? ? token : replaced
            end
          end
        end
      end
    end
  end
end

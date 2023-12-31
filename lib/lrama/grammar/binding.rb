module Lrama
  class Grammar
    class Binding
      attr_reader :actual_args, :count

      def initialize(parameterizing_rule, actual_args)
        @rule_name = parameterizing_rule.name
        @required_parameters_count = parameterizing_rule.required_parameters_count
        @parameters = parameterizing_rule.parameters
        @actual_args = actual_args
        @parameter_to_arg = @parameters.zip(actual_args).map do |param, arg|
          [param.s_value, arg]
        end.to_h
      end

      def resolve_symbol(symbol, lhs_token = nil)
        if symbol.is_a?(Lexer::Token::InstantiateRule)
          if symbol.s_value == @rule_name && symbol.args_count == @required_parameters_count
            lhs_token
          else
            resolved_args = symbol.args.map { |arg| resolve_symbol(arg) }
            Lrama::Lexer::Token::InstantiateRule.new(s_value: symbol.s_value, location: symbol.location, args: resolved_args, lhs_tag: symbol.lhs_tag)
          end
        else
          @parameter_to_arg[symbol.s_value] || symbol
        end
      end
    end
  end
end

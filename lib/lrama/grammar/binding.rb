# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Grammar
    class Binding
      # @rbs (Grammar::ParameterizingRule::Rule parameterizing_rule, Array[Lexer::Token] actual_args) -> void
      def initialize(parameterizing_rule, actual_args)
        @actual_args = actual_args
        @parameter_to_arg = map_params_to_args(parameterizing_rule.parameters, @actual_args)
      end

      # @rbs (Lexer::Token sym) -> Lexer::Token
      def resolve_symbol(sym)
        if sym.is_a?(Lexer::Token::InstantiateRule)
          Lrama::Lexer::Token::InstantiateRule.new(
            s_value: sym.s_value, location: sym.location, args: resolved_args(sym), lhs_tag: sym.lhs_tag
          )
        else
          parameter_to_arg(sym) || sym
        end
      end

      # @rbs (Lexer::Token::InstantiateRule token) -> String
      def concatenated_args_str(token)
        "#{token.rule_name}_#{token_to_args_s_values(token).join('_')}"
      end

      private

      # @rbs (Array[Lexer::Token] params, Array[Lexer::Token] actual_args) -> Hash[String, Lexer::Token]
      def map_params_to_args(params, actual_args)
        params.zip(actual_args).map do |param, arg|
          [param.s_value, arg]
        end.to_h
      end

      # @rbs (Lexer::Token::InstantiateRule sym) -> Array[Lexer::Token]
      def resolved_args(sym)
        sym.args.map { |arg| resolve_symbol(arg) }
      end

      # @rbs (Lexer::Token sym) -> Lexer::Token?
      def parameter_to_arg(sym)
        if (arg = @parameter_to_arg[sym.s_value].dup)
          arg.alias_name = sym.alias_name
        end
        arg
      end

      # @rbs (Lexer::Token::InstantiateRule token) -> Array[String]
      def token_to_args_s_values(token)
        token.args.flat_map do |arg|
          resolved = resolve_symbol(arg)
          if resolved.is_a?(Lexer::Token::InstantiateRule)
            [resolved.s_value] + resolved.args.map(&:s_value)
          else
            [resolved.s_value]
          end
        end
      end
    end
  end
end

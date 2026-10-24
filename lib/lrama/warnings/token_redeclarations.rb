# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  class Warnings
    class TokenRedeclarations
      # @rbs (Lrama::Logger logger) -> void
      def initialize(logger)
        @logger = logger
      end

      # @rbs (Lrama::Grammar grammar) -> void
      def warn(grammar)
        declarations = {} #: Hash[String, Grammar::Node::Token]
        aliases = {} #: Hash[String, String]

        grammar.nodes.each do |node|
          next unless node.is_a?(Grammar::Node::TokenDecl)

          node.tokens.each do |token|
            name = token.id.s_value
            if (previous = declarations[name])
              @logger.warn(token.location.generate_error_message("symbol #{name} redeclared") + "\n" +
                           previous.location.generate_error_message("previous declaration"))
            else
              declarations[name] = token
            end

            if (alias_name = token.alias_name)
              if (previous_alias = aliases[name])
                message =
                  if previous_alias == alias_name
                    "symbol #{alias_name} used more than once as a literal string"
                  else
                    "symbol #{name} given more than one literal string"
                  end
                @logger.warn(token.location.generate_error_message(message))
              else
                aliases[name] = alias_name
              end
            end
          end
        end
      end
    end
  end
end

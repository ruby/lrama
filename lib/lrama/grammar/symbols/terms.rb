module Lrama
  class Grammar
    class Symbols
      class Terms < Base
        def add(id:, alias_name: nil, tag: nil, token_id: nil, replace: false)
          @symbols << Symbol.new(
            id: id, alias_name: alias_name, number: nil, tag: tag,
            term: true, token_id: token_id, nullable: false
          )
        end

        # Fill #number and #token_id
        def fill_symbol_number(used_numbers)
          number = INITIAL_NUMBER
          # Character literal in grammar file has
          # token id corresponding to ASCII code by default,
          # so start token_id from 256.
          token_id = 256

          @symbols.each do |sym|
            while used_numbers[number] do
              number += 1
            end

            if sym.number.nil?
              sym.number = number
              used_numbers[number] = true
              number += 1
            end

            # If id is Token::Char, it uses ASCII code
            if sym.token_id.nil?
              if sym.id.is_a?(Lrama::Lexer::Token::Char)
                # Ignore ' on the both sides
                case sym.id.s_value[1..-2]
                when "\\b"
                  sym.token_id = 8
                when "\\f"
                  sym.token_id = 12
                when "\\n"
                  sym.token_id = 10
                when "\\r"
                  sym.token_id = 13
                when "\\t"
                  sym.token_id = 9
                when "\\v"
                  sym.token_id = 11
                when "\""
                  sym.token_id = 34
                when "'"
                  sym.token_id = 39
                when "\\\\"
                  sym.token_id = 92
                when /\A\\(\d+)\z/
                  sym.token_id = Integer($1, 8)
                when /\A(.)\z/
                  sym.token_id = $1.bytes.first
                else
                  raise "Unknown Char s_value #{sym}"
                end
              else
                sym.token_id = token_id
                token_id += 1
              end
            end
          end
        end
      end
    end
  end
end

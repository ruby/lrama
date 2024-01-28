module Lrama
  class Grammar
    class Symbols
      class Resolver
        attr_reader :terms, :nterms

        def initialize
          @terms = Terms.new
          @nterms = Nterms.new
        end

        def symbols
          @symbols ||= (@terms.symbols + @nterms.symbols)
        end

        def sort_by_number!
          @symbols.sort_by!(&:number)
        end

        def add_term(id:, alias_name: nil, tag: nil, token_id: nil, replace: false)
          if token_id && (sym = find_symbol_by_token_id(token_id))
            if replace
              sym.id = id
              sym.alias_name = alias_name
              sym.tag = tag
            end

            return sym
          end

          if (sym = find_symbol_by_id(id))
            return sym
          end

          @symbols = nil
          @terms.add(id: id, alias_name: alias_name, tag: tag, token_id: token_id).last
        end

        def add_nterm(id:, alias_name: nil, tag: nil)
          return if find_symbol_by_id(id)

          @symbols = nil
          @nterms.add(id: id, alias_name: alias_name, tag: tag).last
        end

        def find_symbol_by_s_value(s_value)
          symbols.find { |s| s.id.s_value == s_value }
        end

        def find_symbol_by_s_value!(s_value)
          find_symbol_by_s_value(s_value) || (raise "Symbol not found: #{s_value}")
        end

        def find_symbol_by_id(id)
          symbols.find do |s|
            s.id == id || s.alias_name == id.s_value
          end
        end

        def find_symbol_by_id!(id)
          find_symbol_by_id(id) || (raise "Symbol not found: #{id}")
        end

        def find_symbol_by_token_id(token_id)
          symbols.find {|s| s.token_id == token_id }
        end

        def find_symbol_by_number!(number)
          sym = symbols[number]

          raise "Symbol not found: #{number}" unless sym
          raise "[BUG] Symbol number mismatch. #{number}, #{sym}" if sym.number != number

          sym
        end

        def fill_symbol_number
          @terms.fill_symbol_number(used_numbers)
          @nterms.fill_symbol_number(used_numbers)
        end

        def fill_nterm_type(types)
          @nterms.fill_type(types)
        end

        def fill_printer(printers)
          symbols.each do |sym|
            printers.each do |printer|
              printer.ident_or_tags.each do |ident_or_tag|
                case ident_or_tag
                when Lrama::Lexer::Token::Ident
                  sym.printer = printer if sym.id == ident_or_tag
                when Lrama::Lexer::Token::Tag
                  sym.printer = printer if sym.tag == ident_or_tag
                else
                  raise "Unknown token type. #{printer}"
                end
              end
            end
          end
        end

        def fill_error_token(error_tokens)
          symbols.each do |sym|
            error_tokens.each do |token|
              token.ident_or_tags.each do |ident_or_tag|
                case ident_or_tag
                when Lrama::Lexer::Token::Ident
                  sym.error_token = token if sym.id == ident_or_tag
                when Lrama::Lexer::Token::Tag
                  sym.error_token = token if sym.tag == ident_or_tag
                else
                  raise "Unknown token type. #{token}"
                end
              end
            end
          end
        end

        def token_to_symbol(token)
          case token
          when Lrama::Lexer::Token
            find_symbol_by_id!(token)
          else
            raise "Unknown class: #{token}"
          end
        end

        def validate!
          validate_number_uniqueness!
          validate_alias_name_uniqueness!
        end

        private

        def used_numbers
          return @used_numbers if defined?(@used_numbers)

          @used_numbers = {}
          @symbols.map(&:number).each do |n|
            @used_numbers[n] = true
          end
          @used_numbers
        end

        def validate_number_uniqueness!
          invalid = symbols.group_by(&:number).select do |number, syms|
            syms.count > 1
          end

          return if invalid.empty?

          raise "Symbol number is duplicated. #{invalid}"
        end

        def validate_alias_name_uniqueness!
          invalid = symbols.select(&:alias_name).group_by(&:alias_name).select do |alias_name, syms|
            syms.count > 1
          end

          return if invalid.empty?

          raise "Symbol alias name is duplicated. #{invalid}"
        end
      end
    end
  end
end

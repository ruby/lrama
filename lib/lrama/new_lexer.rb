require "strscan"

module Lrama
  class NewLexer
    attr_accessor :status
    attr_accessor :end_symbol

    def initialize(text)
      @scanner = StringScanner.new(text)
      @status = :initial
      @end_symbol = nil
    end

    def next_token
      case @status
      when :initial
        lex_token
      when :c_declaration
        lex_c_code
      end
    end

    def col
      @scanner.pos
    end

    def row
      @scanner.pos
    end

    def lex_token
      while !@scanner.eos? do
        case
        when @scanner.scan(/\s+/)
          pp @scanner.matched
          next
        when @scanner.scan(/\/\*[\s\S]*?\*\//)
          pp @scanner.matched
          next
        when @scanner.scan(/%{/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/%}/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/%%/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/{/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/}/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/:/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/\|/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/;/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/%union|%token|%type|%left|%right|%nonassoc|%expect|%define|%require|%printer|%lex-param|%parse-param|%initial-action|%prec/)
          return [@scanner.matched, @scanner.matched]
        when @scanner.scan(/<\w+>/)
          return [:TAG, @scanner.matched]
        when @scanner.scan(/'.'/)
          return [:CHARACTER, @scanner.matched]
        when @scanner.scan(/'\\\\'|'\\t'|'\\f'|'\\r'|'\\n'|'\\13'/)
          return [:CHARACTER, @scanner.matched]
        when @scanner.scan(/"/)
          return [:STRING, @scanner.scan_until(/"/)[0..-2]]
        when @scanner.scan(/\d+/)
          return [:INTEGER, @scanner.matched]
        when @scanner.scan(/([a-zA-Z_.][-a-zA-Z0-9_.()]*)/)
          return [:IDENTIFIER, @scanner.matched]
        else
          raise
        end
      end
    end

    def lex_c_code
      nested = 0
      code = ''
      while !@scanner.eos? do
        case
        when @scanner.scan(/"/)
          code += %Q("#{@scanner.scan_until(/"/)[0..-2]}")
        when @scanner.scan(/{/)
          code += @scanner.matched
          nested += 1
        when @scanner.scan(/}/)
          if nested == 0 && @end_symbol == '}'
            @scanner.unscan
            return [:C_DECLARATION, code]
          else
            code += @scanner.matched
            nested -= 1
          end
        when @scanner.check(/#{@end_symbol}/)
          return [:C_DECLARATION, code]
        else
          code += @scanner.getch
        end
      end
      raise
    end
  end
end

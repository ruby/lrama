require "strscan"

module Lrama
  class NewLexer
    attr_accessor :status
    attr_accessor :end_symbol

    def initialize(text)
      @scanner = StringScanner.new(text)
      @head = @scanner.pos
      @line = 1
      @status = :initial
      @end_symbol = nil
    end

    def next_token
      case @status
      when :initial
        pp @line
        lex_token
      when :c_declaration
        lex_c_code
      end
    end

    def line
      @line
    end

    def col
      @scanner.pos - @head + 1
    end

    def lex_token
      while !@scanner.eos? do
        case
        when @scanner.scan(/\n/)
          @line += 1
          @head = @scanner.pos + 1
        when @scanner.scan(/\s+/)
          # noop
        when @scanner.scan(/\/\*/)
          lex_comment
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
        when @scanner.scan(/([a-zA-Z_.][-a-zA-Z0-9_.]*)/)
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
        when @scanner.scan(/\n/)
          code += @scanner.matched
          @line += 1
          @head = @scanner.pos + 1
        when @scanner.scan(/"/)
          matched = @scanner.scan_until(/"/)[0..-2]
          code += %Q("#{matched}")
          @line += matched.count("\n")
        else
          code += @scanner.getch
        end
      end
      raise
    end

    def lex_comment
      while !@scanner.eos? do
        case
        when @scanner.scan(/\n/)
          @line += 1
          @head = @scanner.pos + 1
        when @scanner.scan(/\*\//)
          return
        else
          @scanner.getch
        end
      end
    end
  end
end

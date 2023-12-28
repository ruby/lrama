module Lrama
  class Binding
    attr_reader :actual_args, :count

    def initialize(parameters, actual_args)
      @parameters = parameters
      @actual_args = actual_args
      @count = parameters.count
      @parameter_to_arg = parameters.zip(actual_args).map do |param, arg|
        [param.s_value, arg]
      end.to_h
    end

    def resolve_symbol(symbol)
      if symbol.is_a?(Lexer::Token::InstantiateRule)
        symbol.args.map! { |arg| resolve_symbol(arg) }
        symbol
      else
        @parameter_to_arg[symbol.s_value] || symbol
      end
    end
  end
end

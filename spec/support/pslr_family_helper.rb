# frozen_string_literal: true

module PslrFamilyHelper
  def build_grammar(source, path)
    grammar = Lrama::Parser.new(source, path).parse
    grammar.prepare
    grammar.validate!
    grammar
  end

  def compute_ielr_and_pslr(grammar)
    ielr_states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    ielr_states.compute
    ielr_states.compute_ielr

    pslr_states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
    pslr_states.compute
    pslr_states.compute_pslr

    [ielr_states, pslr_states]
  end

  def acceptable_tokens(states, state)
    states.send(:acceptable_tokens_for_pslr, state).to_a
  end

  def shared_chain_rules(name:, terminal:, depth:, prefix: "n")
    return <<~RULES if depth.zero?
      #{name}
        : #{terminal}
        ;
    RULES

    rules = [<<~RULE]
      #{name}
        : #{prefix}1
        ;
    RULE

    1.upto(depth - 1) do |index|
      rules << <<~RULE
        #{prefix}#{index}
          : #{prefix}#{index + 1}
          ;
      RULE
    end

    rules << <<~RULE
      #{prefix}#{depth}
        : #{terminal}
        ;
    RULE

    rules.join("\n")
  end

  def keyword_context_source(depth:)
    <<~GRAMMAR
      %define lr.type pslr
      %token-pattern P /p/
      %token-pattern Q /q/
      %token-pattern X /x/
      %token-pattern IF /if/
      %token-pattern ID /[a-z]+/
      %lex-prec ID <~ IF

      %%

      program
        : kw_context
        | id_context
        ;

      kw_context
        : P shared IF
        ;

      id_context
        : Q shared ID
        ;

      #{shared_chain_rules(name: "shared", terminal: "X", depth: depth)}
    GRAMMAR
  end

  def shift_angle_source(depth:)
    <<~GRAMMAR
      %define lr.type pslr
      %token-pattern LT /</
      %token-pattern START /@/
      %token-pattern MARK /#/
      %token-pattern RSHIFT />>/
      %token-pattern RANGLE />/
      %token-pattern ID /[a-z]+/
      %lex-prec RANGLE -s RSHIFT

      %%

      program
        : template_expr
        | shift_expr
        ;

      template_expr
        : LT shared RANGLE
        ;

      shift_expr
        : START shared RSHIFT ID
        ;

      #{shared_chain_rules(name: "shared", terminal: "MARK", depth: depth)}
    GRAMMAR
  end

  def mixed_context_source(depth:)
    <<~GRAMMAR
      %define lr.type pslr
      %token-pattern LT /</
      %token-pattern START /@/
      %token-pattern P /p/
      %token-pattern Q /q/
      %token-pattern MARK /#/
      %token-pattern IF /if/
      %token-pattern ID /[a-z]+/
      %token-pattern RSHIFT />>/
      %token-pattern RANGLE />/
      %lex-prec ID <~ IF
      %lex-prec RANGLE -s RSHIFT

      %%

      program
        : kw_context
        | id_context
        | template_expr
        | shift_expr
        ;

      kw_context
        : P shared IF
        ;

      id_context
        : Q shared ID
        ;

      template_expr
        : LT shared RANGLE
        ;

      shift_expr
        : START shared RSHIFT ID
        ;

      #{shared_chain_rules(name: "shared", terminal: "MARK", depth: depth)}
    GRAMMAR
  end
end

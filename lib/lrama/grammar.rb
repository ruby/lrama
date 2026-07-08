# rbs_inline: enabled
# frozen_string_literal: true

require "forwardable"
require "set"
require_relative "grammar/auxiliary"
require_relative "grammar/binding"
require_relative "grammar/code"
require_relative "grammar/counter"
require_relative "grammar/destructor"
require_relative "grammar/error_token"
require_relative "grammar/inline"
require_relative "grammar/node"
require_relative "grammar/parameterized"
require_relative "grammar/percent_code"
require_relative "grammar/precedence"
require_relative "grammar/printer"
require_relative "grammar/reference"
require_relative "grammar/rule"
require_relative "grammar/rule_builder"
require_relative "grammar/symbol"
require_relative "grammar/symbols"
require_relative "grammar/type"
require_relative "grammar/union"
require_relative "grammar/token_pattern"
require_relative "grammar/token_action"
require_relative "grammar/lex_prec"
require_relative "grammar/lex_tie"
require_relative "grammar/lexer_context"
require_relative "lexer"

module Lrama
  # Grammar is the result of parsing an input grammar file
  class Grammar
    # @rbs!
    #
    #   interface _DelegatedMethods
    #     def rules: () -> Array[Rule]
    #     def accept_symbol: () -> Grammar::Symbol
    #     def eof_symbol: () -> Grammar::Symbol
    #     def undef_symbol: () -> Grammar::Symbol
    #     def precedences: () -> Array[Precedence]
    #
    #     # delegate to @symbols_resolver
    #     def symbols: () -> Array[Grammar::Symbol]
    #     def terms: () -> Array[Grammar::Symbol]
    #     def nterms: () -> Array[Grammar::Symbol]
    #     def find_symbol_by_s_value!: (::String s_value) -> Grammar::Symbol
    #     def ielr_defined?: () -> bool
    #     def pslr_defined?: () -> bool
    #     def token_patterns: () -> Array[Grammar::TokenPattern]
    #     def lex_prec: () -> Grammar::LexPrec
    #     def pslr_max_states: () -> Integer?
    #     def pslr_max_state_ratio: () -> Float?
    #   end
    #
    #   include Symbols::Resolver::_DelegatedMethods
    #
    #   @rule_counter: Counter
    #   @percent_codes: Array[PercentCode]
    #   @printers: Array[Printer]
    #   @destructors: Array[Destructor]
    #   @error_tokens: Array[ErrorToken]
    #   @symbols_resolver: Symbols::Resolver
    #   @types: Array[Type]
    #   @rule_builders: Array[RuleBuilder]
    #   @rules: Array[Rule]
    #   @sym_to_rules: Hash[Integer, Array[Rule]]
    #   @parameterized_resolver: Parameterized::Resolver
    #   @empty_symbol: Grammar::Symbol
    #   @eof_symbol: Grammar::Symbol
    #   @error_symbol: Grammar::Symbol
    #   @undef_symbol: Grammar::Symbol
    #   @accept_symbol: Grammar::Symbol
    #   @aux: Auxiliary
    #   @no_stdlib: bool
    #   @locations: bool
    #   @define: Hash[String, String?]
    #   @required: bool
    #   @union: Union
    #   @precedences: Array[Precedence]
    #   @start_nterm: Lrama::Lexer::Token::Base?
    #   @token_patterns: Array[Grammar::TokenPattern]
    #   @lex_prec: Grammar::LexPrec
    #   @symbol_sets: Hash[String, Array[Lexer::Token::Base]]
    #   @lex_tie: Grammar::LexTie
    #   @nodes: Array[Node::Base]

    extend Forwardable

    attr_reader :percent_codes #: Array[PercentCode]
    attr_reader :eof_symbol #: Grammar::Symbol
    attr_reader :error_symbol #: Grammar::Symbol
    attr_reader :undef_symbol #: Grammar::Symbol
    attr_reader :accept_symbol #: Grammar::Symbol
    attr_reader :aux #: Auxiliary
    attr_reader :parameterized_resolver #: Parameterized::Resolver
    attr_reader :precedences #: Array[Precedence]
    attr_accessor :union #: Union
    attr_accessor :expect #: Integer
    attr_accessor :printers #: Array[Printer]
    attr_accessor :error_tokens #: Array[ErrorToken]
    attr_reader :lex_params #: Array[String]
    attr_reader :parse_params #: Array[String]
    attr_accessor :initial_action #: Grammar::Code::InitialActionCode
    attr_accessor :after_shift #: Lexer::Token::Base
    attr_accessor :before_reduce #: Lexer::Token::Base
    attr_accessor :after_reduce #: Lexer::Token::Base
    attr_accessor :after_shift_error_token #: Lexer::Token::Base
    attr_accessor :after_pop_stack #: Lexer::Token::Base
    attr_accessor :symbols_resolver #: Symbols::Resolver
    attr_accessor :types #: Array[Type]
    attr_accessor :rules #: Array[Rule]
    attr_accessor :rule_builders #: Array[RuleBuilder]
    attr_accessor :sym_to_rules #: Hash[Integer, Array[Rule]]
    attr_accessor :no_stdlib #: bool
    attr_accessor :locations #: bool
    attr_accessor :define #: Hash[String, String?]
    attr_accessor :required #: bool
    attr_accessor :nodes #: Array[Node::Base]
    attr_reader :token_patterns #: Array[Grammar::TokenPattern]
    attr_reader :lex_prec #: Grammar::LexPrec
    attr_reader :symbol_sets #: Hash[String, Array[Lexer::Token::Base]]
    attr_reader :lex_tie #: Grammar::LexTie
    attr_reader :lexer_contexts #: Hash[String, Grammar::LexerContext]
    attr_reader :token_actions #: Array[Grammar::TokenAction]

    # Argument symbol names for each parameterized rule expansion.
    # @rbs () -> Hash[String, Array[String]]
    def parameterized_expansion_args
      @parameterized_resolver.expansion_args
    end

    def_delegators "@symbols_resolver", :symbols, :nterms, :terms, :add_nterm, :add_term, :find_term_by_s_value,
                                        :find_symbol_by_number!, :find_symbol_by_id!,
                                        :find_symbol_by_s_value!, :fill_symbol_number, :fill_nterm_type,
                                        :fill_printer, :fill_destructor, :fill_error_token, :sort_by_number!

    # @rbs (Counter rule_counter, bool locations, Hash[String, String?] define) -> void
    def initialize(rule_counter, midrule_action_counter, locations, define = {})
      @rule_counter = rule_counter
      @midrule_action_counter = midrule_action_counter

      # Code defined by "%code"
      @percent_codes = []
      @printers = []
      @destructors = []
      @error_tokens = []
      @lex_params = []
      @parse_params = []
      @symbols_resolver = Grammar::Symbols::Resolver.new
      @types = []
      @rule_builders = []
      @rules = []
      @sym_to_rules = {}
      @parameterized_resolver = Parameterized::Resolver.new
      @empty_symbol = nil
      @eof_symbol = nil
      @error_symbol = nil
      @undef_symbol = nil
      @accept_symbol = nil
      @aux = Auxiliary.new
      @no_stdlib = false
      @locations = locations
      @define = define
      @required = false
      @precedences = []
      @start_nterm = nil
      @token_patterns = []
      @lex_prec = Grammar::LexPrec.new
      @symbol_sets = {}
      @lex_tie = Grammar::LexTie.new
      @lexer_contexts = {}
      @lexer_context_counter = 0
      @token_pattern_counter = 0
      @token_actions = []
      @nodes = nil

      append_special_symbols
    end

    # @rbs () -> void
    def evaluate_nodes
      _evaluate_nodes
    end

    # @rbs (Counter rule_counter, Counter midrule_action_counter) -> RuleBuilder
    def create_rule_builder(rule_counter, midrule_action_counter)
      RuleBuilder.new(rule_counter, midrule_action_counter, @parameterized_resolver)
    end

    # @rbs (id: Lexer::Token::Base, code: Lexer::Token::UserCode) -> Array[PercentCode]
    def add_percent_code(id:, code:)
      @percent_codes << PercentCode.new(id.s_value, code.s_value)
    end

    # @rbs (ident_or_tags: Array[Lexer::Token::Ident|Lexer::Token::Tag], token_code: Lexer::Token::UserCode, lineno: Integer) -> Array[Destructor]
    def add_destructor(ident_or_tags:, token_code:, lineno:)
      @destructors << Destructor.new(ident_or_tags: ident_or_tags, token_code: token_code, lineno: lineno)
    end

    # @rbs (ident_or_tags: Array[Lexer::Token::Ident|Lexer::Token::Tag], token_code: Lexer::Token::UserCode, lineno: Integer) -> Array[Printer]
    def add_printer(ident_or_tags:, token_code:, lineno:)
      @printers << Printer.new(ident_or_tags: ident_or_tags, token_code: token_code, lineno: lineno)
    end

    # @rbs (ident_or_tags: Array[Lexer::Token::Ident|Lexer::Token::Tag], token_code: Lexer::Token::UserCode, lineno: Integer) -> Array[ErrorToken]
    def add_error_token(ident_or_tags:, token_code:, lineno:)
      @error_tokens << ErrorToken.new(ident_or_tags: ident_or_tags, token_code: token_code, lineno: lineno)
    end

    # @rbs (id: Lexer::Token::Base, tag: Lexer::Token::Tag?) -> Array[Type]
    def add_type(id:, tag:)
      @types << Type.new(id: Grammar::Symbol::Id.from_token(id), tag: tag)
    end

    # @rbs (Grammar::Symbol sym, Integer precedence, Integer lineno) -> Precedence
    def add_nonassoc(sym, precedence, lineno)
      set_precedence(sym, Precedence.new(symbol: sym, type: :nonassoc, precedence: precedence, lineno: lineno))
    end

    # @rbs (Grammar::Symbol sym, Integer precedence, Integer lineno) -> Precedence
    def add_left(sym, precedence, lineno)
      set_precedence(sym, Precedence.new(symbol: sym, type: :left, precedence: precedence, lineno: lineno))
    end

    # @rbs (Grammar::Symbol sym, Integer precedence, Integer lineno) -> Precedence
    def add_right(sym, precedence, lineno)
      set_precedence(sym, Precedence.new(symbol: sym, type: :right, precedence: precedence, lineno: lineno))
    end

    # @rbs (Grammar::Symbol sym, Integer precedence, Integer lineno) -> Precedence
    def add_precedence(sym, precedence, lineno)
      set_precedence(sym, Precedence.new(symbol: sym, type: :precedence, precedence: precedence, lineno: lineno))
    end

    # @rbs (Lrama::Lexer::Token::Base id) -> Lrama::Lexer::Token::Base
    def set_start_nterm(id)
      # When multiple `%start` directives are defined, Bison does not generate an error,
      # whereas Lrama does generate an error.
      # Related Bison's specification are
      #   refs: https://www.gnu.org/software/bison/manual/html_node/Multiple-start_002dsymbols.html
      if @start_nterm.nil?
        @start_nterm = id
      else
        start = @start_nterm #: Lrama::Lexer::Token::Base
        raise "Start non-terminal is already set to #{start.s_value} (line: #{start.first_line}). Cannot set to #{id.s_value} (line: #{id.first_line})."
      end
    end

    # @rbs (Grammar::Symbol sym, Precedence precedence) -> (Precedence | bot)
    def set_precedence(sym, precedence)
      @precedences << precedence
      sym.precedence = precedence
    end

    # @rbs (Grammar::Code::NoReferenceCode code, Integer lineno) -> Union
    def set_union(code, lineno)
      @union = Union.new(code: code, lineno: lineno)
    end

    # @rbs (RuleBuilder builder) -> Array[RuleBuilder]
    def add_rule_builder(builder)
      @rule_builders << builder
    end

    # @rbs (Parameterized::Rule rule) -> Array[Parameterized::Rule]
    def add_parameterized_rule(rule)
      @parameterized_resolver.add_rule(rule)
    end

    # @rbs () -> Array[Parameterized::Rule]
    def parameterized_rules
      @parameterized_resolver.rules
    end

    # @rbs (Array[Parameterized::Rule] rules) -> Array[Parameterized::Rule]
    def prepend_parameterized_rules(rules)
      @parameterized_resolver.rules = rules + @parameterized_resolver.rules
    end

    # @rbs (Integer prologue_first_lineno) -> Integer
    def prologue_first_lineno=(prologue_first_lineno)
      @aux.prologue_first_lineno = prologue_first_lineno
    end

    # @rbs (String prologue) -> String
    def prologue=(prologue)
      @aux.prologue = prologue
    end

    # @rbs (Integer epilogue_first_lineno) -> Integer
    def epilogue_first_lineno=(epilogue_first_lineno)
      @aux.epilogue_first_lineno = epilogue_first_lineno
    end

    # @rbs (String epilogue) -> String
    def epilogue=(epilogue)
      @aux.epilogue = epilogue
    end

    # @rbs () -> void
    def prepare
      resolve_inline_rules
      normalize_rules
      collect_symbols
      set_lhs_and_rhs
      resolve_lexical_aliases
      fill_default_precedence
      fill_symbols
      fill_sym_to_rules
      sort_precedence
      compute_nullable
      compute_first_set
      set_locations
    end

    # TODO: More validation methods
    #
    # * Validation for no_declared_type_reference
    #
    # @rbs () -> void
    def validate!
      @symbols_resolver.validate!
      validate_no_precedence_for_nterm!
      validate_rule_lhs_is_nterm!
      validate_duplicated_precedence!
      validate_pslr_configuration!
    end

    # @rbs (Grammar::Symbol sym) -> Array[Rule]
    def find_rules_by_symbol!(sym)
      find_rules_by_symbol(sym) || (raise "Rules for #{sym} not found")
    end

    # @rbs (Grammar::Symbol sym) -> Array[Rule]?
    def find_rules_by_symbol(sym)
      @sym_to_rules[sym.number]
    end

    # @rbs (String s_value) -> Array[Rule]
    def select_rules_by_s_value(s_value)
      @rules.select {|rule| rule.lhs.name == s_value }
    end

    # @rbs () -> Array[String]
    def unique_rule_s_values
      @rules.map {|rule| rule.lhs.name }.uniq
    end

    # @rbs () -> bool
    def ielr_defined?
      @define.key?('lr.type') && @define['lr.type'] == 'ielr'
    end

    # @rbs () -> bool
    def pslr_defined?
      @define.key?('lr.type') && @define['lr.type'] == 'pslr'
    end

    # @rbs () -> String?
    def pslr_state_member
      @define['api.pslr.state-member']
    end

    # @rbs () -> Integer?
    def pslr_max_states
      parse_pslr_positive_integer('pslr.max-states')
    end

    # @rbs () -> Float?
    def pslr_max_state_ratio
      parse_pslr_positive_float('pslr.max-state-ratio')
    end

    # True when the generated parser owns lexical analysis completely
    # (%define api.pslr.lexer generated, the paper's own model).
    # @rbs () -> bool
    def pslr_lexer_generated?
      @define['api.pslr.lexer'] == 'generated'
    end

    # Base table construction for PSLR: extended IELR (default) or
    # canonical LR(1) for debugging unresolved-conflict reports whose
    # contexts would otherwise be merged (section 3.4.3).
    # @rbs () -> String
    def pslr_tables
      value = @define['pslr.tables']
      return 'ielr' if value.nil? || value.empty?

      value
    end

    # @rbs () -> bool
    def pslr_canonical_tables?
      pslr_defined? && pslr_tables == 'canonical-lr'
    end

    # Terminals that the pseudo-scanner cannot produce: real terminals
    # used by the grammar that have no %token-pattern (explicit or
    # synthesized). Pure mode requires this list to be empty; bridge
    # mode reports it so users know which tokens their yylex must keep
    # producing.
    # @rbs () -> Array[String]
    def uncovered_pslr_terminals
      covered = @token_patterns.map(&:name).to_set

      terms.reject do |term|
        term == eof_symbol || term == error_symbol || term == undef_symbol ||
          covered.include?(term.name)
      end.map(&:name)
    end

    # LAC (lookahead correction) setting from %define parse.lac.
    # PSLR parsers default to full because exploratory parses are what
    # keep merged-state pseudo-scanning canonical-equivalent; other
    # parser types default to none for Bison compatibility.
    # @rbs () -> String
    def parse_lac
      value = @define['parse.lac']
      return (pslr_defined? ? 'full' : 'none') if value.nil? || value.empty?

      value
    end

    # @rbs () -> bool
    def parse_lac_full?
      parse_lac == 'full'
    end

    # @rbs () -> bool
    def parse_lac_explicit_none?
      @define['parse.lac'] == 'none'
    end

    # @rbs () -> Array[Grammar::TokenPattern]
    def layout_token_patterns
      @token_patterns.select(&:layout?)
    end

    # @rbs () -> Set[String]
    def layout_token_names
      layout_token_patterns.map(&:name).to_set
    end

    # Add a token pattern from %token-pattern directive
    # @rbs (id: Lexer::Token::Ident, pattern: Lexer::Token::Regex, ?alias_name: String?, ?tag: Lexer::Token::Tag?, lineno: Integer) -> Grammar::TokenPattern
    def add_token_pattern(id:, pattern:, alias_name: nil, tag: nil, lineno:)
      token_pattern = Grammar::TokenPattern.new(
        id: id,
        pattern: pattern,
        alias_name: alias_name,
        tag: tag,
        lineno: lineno,
        definition_order: @token_pattern_counter
      )
      @token_pattern_counter += 1
      @token_patterns << token_pattern

      symbol_id = Grammar::Symbol::Id.from_token(id)
      existing = @symbols_resolver.find_symbol_by_id(symbol_id)
      term = add_term(id: symbol_id, alias_name: existing&.alias_name || alias_name, location: id.location)
      term.alias_name = alias_name if alias_name
      term.tag = tag if tag

      token_pattern
    end

    # Add a symbol set from %symbol-set directive.
    # @rbs (name: String, symbols: Array[Lexer::Token::Base]) -> Array[Lexer::Token::Base]
    def add_symbol_set(name:, symbols:)
      @symbol_sets[name] = symbols.map {|id| canonical_lexical_operand(id) }
    end

    # Add lex-prec rules from %lex-prec directive.
    # Stores as raw declaration for delayed expansion after implicit literal synthesis.
    # @rbs (left_token: Lexer::Token::Base, operator: Symbol, right_token: Lexer::Token::Base, lineno: Integer) -> Grammar::LexPrec::Declaration
    def add_lex_prec_rule(left_token:, operator:, right_token:, lineno:)
      # Register terminals so they are known to the symbol resolver
      canonical_lexical_operand(left_token) unless left_token.s_value == "yyall" || @symbol_sets.key?(left_token.s_value)
      canonical_lexical_operand(right_token) unless right_token.s_value == "yyall" || @symbol_sets.key?(right_token.s_value)

      @lex_prec.add_declaration(
        left_operand: left_token,
        operator: operator,
        right_operand: right_token,
        lineno: lineno
      )
    end

    # Finalize lexical declarations after implicit literal synthesis.
    # Expands yyall and symbol-set operands using the post-synthesis token universe.
    # Validates that identity-component operators are not used as self-pairs.
    # @rbs () -> void
    def finalize_lexical_declarations!
      @lex_prec.declarations.each do |decl|
        expand_pslr_operand(decl.left_operand).product(expand_pslr_operand(decl.right_operand)).each do |left, right|
          validate_lex_prec_self_pair!(left, right, decl.operator, decl.lineno)
          next if left.s_value == right.s_value && Grammar::LexPrec::IDENTITY_OPERATORS.include?(decl.operator)

          @lex_prec.add_rule(
            left_token: left,
            operator: decl.operator,
            right_token: right,
            lineno: decl.lineno
          )
        end
      end
    end

    # Add lexical tie relationships from %lex-tie directive.
    # @rbs (operands: Array[Lexer::Token::Base]) -> void
    def add_lex_tie(operands:)
      groups = operands.map {|operand| pslr_operand_group(operand) }
      @lex_tie.add_tie_declaration(groups: groups)
    end

    # Add no-tie declarations from %lex-no-tie directive.
    # @rbs (operands: Array[Lexer::Token::Base]) -> void
    def add_lex_no_tie(operands:)
      groups = operands.map {|operand| pslr_operand_group(operand) }
      @lex_tie.add_no_tie_declaration(groups: groups)
      expanded = groups.map {|group| group.names.map {|name| Lrama::Lexer::Token::Ident.new(s_value: name) } }
      i = 0
      while i < expanded.size
        j = i + 1
        while j < expanded.size
          left_group = expanded.fetch(i)
          right_group = expanded.fetch(j)
          left_group.product(right_group).each do |left, right|
            next if left.s_value == right.s_value

            @lex_tie.add_no_tie(left.s_value, right.s_value)
          end
          j += 1
        end
        i += 1
      end
    end

    # Add a lexer context from %lexer-context directive
    # @rbs (name: String, symbols: Array[Lexer::Token::Base]) -> Grammar::LexerContext
    def add_lexer_context(name:, symbols:)
      unless /\A[a-zA-Z_][a-zA-Z_0-9]*\z/.match?(name)
        raise "%lexer-context name must be a valid C identifier, got #{name.inspect}."
      end

      unless ctx = @lexer_contexts[name]
        ctx = Grammar::LexerContext.new(name: name, index: @lexer_context_counter)
        @lexer_context_counter += 1
        @lexer_contexts[name] = ctx
      end
      ctx.add_symbols(symbols)
      ctx
    end

    # Add a token action from %token-action directive
    # @rbs (id: Lexer::Token::Ident, code: Lexer::Token::UserCode, lineno: Integer) -> Grammar::TokenAction
    def add_token_action(id:, code:, lineno:)
      token_action = Grammar::TokenAction.new(
        token_id: id,
        code: code,
        lineno: lineno
      )
      @token_actions << token_action
      token_action
    end

    # Find a token pattern by its name
    # @rbs (String name) -> Grammar::TokenPattern?
    def find_token_pattern(name)
      @token_patterns.find { |tp| tp.name == name }
    end

    # @rbs (Set[String] tokens) -> Set[String]
    def expand_lexical_ties(tokens)
      tokens.each_with_object(Set.new) do |token, expanded|
        @lex_tie.tied_names(token).each {|name| expanded << name }
      end
    end

    # @rbs (ScannerFSA scanner_fsa) -> void
    def finalize_lexical_ties!(scanner_fsa)
      @lex_tie.finalize!(
        @token_patterns.map(&:name),
        scanner_fsa.pairwise_conflict_pairs
      )
    end

    REGEX_LITERAL_ESCAPES = ["/", "\\", "*", "+", "?", "(", ")", "[", "]", "{", "}", ".", "|", "^", "$", "-"].freeze #: Array[String]
    REGEX_CONTROL_ESCAPES = {
      "\n" => "\\n",
      "\t" => "\\t",
      "\r" => "\\r",
      "\f" => "\\f",
      "\v" => "\\v"
    }.freeze #: Hash[String, String]

    # @rbs () -> void
    def synthesize_implicit_literal_token_patterns!
      existing_names = @token_patterns.map(&:name).to_set

      locations = {} #: Hash[String, Lexer::Location]
      @rules.each do |rule|
        rule._rhs.each_with_index do |id, index|
          location = rule._rhs_locations&.[](index)
          locations[id.name] ||= location if location && !id.ident?
        end
      end

      terms.each do |term|
        pattern = implicit_literal_regex_pattern(term)
        next unless pattern
        next if existing_names.include?(term.name)

        @token_patterns << Grammar::TokenPattern.new(
          id: Lexer::Token::Ident.new(s_value: term.name, location: locations[term.name]),
          pattern: Lexer::Token::Regex.new(s_value: "/#{pattern}/", location: locations[term.name]),
          lineno: locations[term.name]&.first_line || 0,
          definition_order: @token_pattern_counter
        )
        @token_pattern_counter += 1
        existing_names << term.name
      end
    end

    private

    # Validate that identity-component operators are not applied to self-pairs.
    # Self-pair is allowed only for length-only operators (-~ and -s).
    # @rbs (Lexer::Token::Base left, Lexer::Token::Base right, Symbol operator, Integer lineno) -> void
    def validate_lex_prec_self_pair!(left, right, operator, lineno)
      return unless left.s_value == right.s_value

      # Length-only operators are fine for self-pairs (e.g., %lex-prec COM -s COM)
      return if operator == Grammar::LexPrec::LONGEST
      return if operator == Grammar::LexPrec::SHORTEST

      # Identity-component operators on self-pairs are errors
      if Grammar::LexPrec::IDENTITY_OPERATORS.include?(operator)
        raise "%lex-prec self-pair identity rule is invalid: #{left.s_value} cannot have an identity conflict with itself (line #{lineno})."
      end

      # TOKEN_RIGHT_LENGTH (-<) on self-pair is contradictory
      if operator == Grammar::LexPrec::TOKEN_RIGHT_LENGTH
        raise "%lex-prec self-pair with -< is contradictory: #{left.s_value} (line #{lineno})."
      end
    end

    # @rbs (Grammar::Symbol term) -> String?
    def implicit_literal_regex_pattern(term)
      literal =
        case term.id.kind
        when :char
          term.character_code.chr
        when :string
          term.name[1..-2]
        end
      return if !literal || literal.empty? || !literal.ascii_only?

      escape_regex_literal(literal)
    end

    # @rbs (String literal) -> String
    def escape_regex_literal(literal)
      escaped = REGEX_CONTROL_ESCAPES[literal]
      return escaped if escaped

      literal.each_char.map do |char|
        if REGEX_LITERAL_ESCAPES.include?(char)
          "\\#{char}"
        else
          char
        end
      end.join
    end

    # @rbs () -> void
    def validate_pslr_configuration!
      return unless pslr_defined?

      member = pslr_state_member
      if member && member !~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
        raise %(%define api.pslr.state-member must be a valid C identifier, got "#{member}".)
      end

      pslr_max_states
      pslr_max_state_ratio
    end

    # @rbs () -> void
    def validate_parse_lac!
      value = @define['parse.lac']
      return if value.nil? || value.empty?
      return if %w[full none].include?(value)

      raise %(%define parse.lac must be "full" or "none", got "#{value}".)
    end

    # Layout tokens are consumed by the pseudo-scanner and never reach
    # the parser, so they must not appear in grammar rules (section 3.6).
    # @rbs () -> void
    def validate_no_layout_tokens_in_rules!
      @rules.each do |rule|
        rule.rhs.each do |sym|
          next unless sym.term?
          next unless sym.name.start_with?("YYLAYOUT")

          raise "layout token #{sym.name} must not appear in a grammar rule (line #{rule.lineno})."
        end
      end
    end

    # @rbs (Node::Base node) -> void
    def validate_character_literals_in(node)
      case node
      when Node::TokenDecl, Node::PrecedenceDecl
        node.tokens.each { |token| validate_character_literals_in(token) }
      when Node::TypeDecl, Node::NtermDecl
        node.symbols.each { |symbol| validate_character_literals_in(symbol) }
      when Node::SymbolSetDecl, Node::LexerContextDecl
        node.symbols.each { |symbol| validate_character_token!(symbol) }
      when Node::LexTieDecl
        node.operands.each { |operand| validate_character_token!(operand) }
      when Node::LexPrecDecl
        validate_character_token!(node.left)
        validate_character_token!(node.right)
      when Node::Rule
        node.rhs.each { |rhs_node| validate_character_literals_in(rhs_node) }
      when Node::ParameterizedRule
        node.rhs_list.each do |rhs|
          rhs.each { |rhs_node| validate_character_literals_in(rhs_node) }
        end
      when Node::Token, Node::Symbol
        validate_character_token!(node.id)
      when Node::RuleRhs::Symbol, Node::RuleRhs::Prec
        validate_character_token!(node.token)
      when Node::RuleRhs::InstantiateRule
        node.args.each { |arg| validate_character_literals_in(arg) }
      end
    end

    # @rbs (Lexer::Token::Base token) -> void
    def validate_character_token!(token)
      return unless token.is_a?(Lexer::Token::Char)

      token.validate
      return if token.errors.empty?

      raise ParseError, token.location.generate_error_message(token.errors.join("\n"))
    end

    # @rbs () -> void
    def _evaluate_nodes
      @nodes.each do |node|
        validate_character_literals_in(node)

        case node
        when Node::DefineDecl
          self.define[node.variable] = node.value
        when Node::ExpectDecl
          self.expect = node.number
        when Node::PrologueDecl
          self.prologue_first_lineno = node.location.first_line
          self.prologue = node.code.s_value
        when Node::EpilogueDecl
          self.epilogue_first_lineno = node.location.first_line + 1
          self.epilogue = node.code.s_value
        when Node::RequireDecl
          @required = true
        when Node::ParamDecl
          node.params.each do |param|
            code = Grammar::Code::NoReferenceCode.new(type: :param, token_code: param).token_code.s_value
            lex_params << code
            parse_params << code
          end
        when Node::LexParamDecl
          node.params.each do |param|
            lex_params << Grammar::Code::NoReferenceCode.new(type: :lex_param, token_code: param).token_code.s_value
          end
        when Node::ParseParamDecl
          node.params.each do |param|
            parse_params << Grammar::Code::NoReferenceCode.new(type: :parse_param, token_code: param).token_code.s_value
          end
        when Node::UnionDecl
          self.set_union(
            Grammar::Code::NoReferenceCode.new(type: :union, token_code: node.code),
            node.loc.first_line
          )
        when Node::DestructorDecl
          self.add_destructor(
            ident_or_tags: node.ident_or_tags,
            token_code: node.code,
            lineno: node.location.first_line
          )
        when Node::PrinterDecl
          self.add_printer(
            ident_or_tags: node.ident_or_tags,
            token_code: node.code,
            lineno: node.location.first_line
          )
        when Node::ErrorTokenDecl
          self.add_error_token(
            ident_or_tags: node.ident_or_tags,
            token_code: node.code,
            lineno: node.location.first_line
          )
        when Node::StartDecl
          self.set_start_nterm(node.id)
        when Node::CodeDecl
          add_percent_code(id: node.id, code: node.code)
        when Node::InitialActionDecl
          self.initial_action = Grammar::Code::InitialActionCode.new(type: :initial_action, token_code: node.code)
        when Node::NoStdlibDecl
          self.no_stdlib = true
        when Node::LocationsDecl
          self.locations = true
        when Node::AfterShiftDecl
          self.after_shift = node.id
        when Node::BeforeReduceDecl
          self.before_reduce = node.id
        when Node::AfterReduceDecl
          self.after_reduce = node.id
        when Node::AfterShiftErrorTokenDecl
          self.after_shift_error_token = node.id
        when Node::AfterPopStackDecl
          self.after_pop_stack = node.id
        when Node::TokenPatternDecl
          add_token_pattern(id: node.id, pattern: node.pattern, alias_name: node.alias_name, tag: node.tag, lineno: node.id.first_line)
        when Node::TokenActionDecl
          add_token_action(id: node.id, code: node.code, lineno: node.id.first_line)
        when Node::LexerContextDecl
          add_lexer_context(name: node.name, symbols: node.symbols)
        when Node::SymbolSetDecl
          add_symbol_set(name: node.name, symbols: node.symbols)
        when Node::LexPrecDecl
          add_lex_prec_rule(left_token: node.left, operator: node.operator, right_token: node.right, lineno: node.left.first_line)
        when Node::LexTieDecl
          if node.kind == :tie
            add_lex_tie(operands: node.operands)
          else
            add_lex_no_tie(operands: node.operands)
          end
        when Node::TokenDecl
          node.tokens.each do |token|
            add_term(id: Grammar::Symbol::Id.from_token(token.id), alias_name: token.alias_name, token_id: token.token_id, tag: token.tag, replace: true, location: token.id.location)
          end
        when Node::TypeDecl
          node.symbols.each do |sym|
            add_type(id: sym.id, tag: sym.tag)
          end
        when Node::NtermDecl
          node.symbols.each do |sym|
            if find_term_by_s_value(sym.id.s_value)
              raise ParseError, sym.id.location.generate_error_message("symbol #{sym.id.s_value} redeclared as a nonterminal")
            else
              add_type(id: sym.id, tag: sym.tag)
            end
          end
        when Node::PrecedenceDecl
          node.tokens.each do |token|
            sym = add_term(id: Grammar::Symbol::Id.from_token(token.id), tag: token.tag, location: token.id.location)

            case node.type
            when :left
              add_left(sym, node.number, token.loc.first_line)
            when :right
              add_right(sym, node.number, token.loc.first_line)
            when :precedence
              add_precedence(sym, node.number, token.loc.first_line)
            when :nonassoc
              add_nonassoc(sym, node.number, token.loc.first_line)
            else
              raise "Unknown precedence type: #{node.type}, Node: #{node}"
            end
          end
        when Node::Rule
          builder = create_rule_builder(@rule_counter, @midrule_action_counter)
          builder.line = (node.rhs.first || node).location.first_line
          lhs = node.id
          builder.lhs = Grammar::Symbol::Id.from_token(lhs)
          builder.lhs_location = lhs.location
          builder.lhs_alias_name = node.alias_name

          node.rhs.each do |rhs_node|
            case rhs_node
            when Node::RuleRhs::Empty
              builder.line = rhs_node.location.first_line
              builder.add_rhs(rhs_node)
            when Node::RuleRhs::Symbol
              builder.add_rhs(rhs_node)
            when Node::RuleRhs::InstantiateRule
              builder.add_rhs(rhs_node)
              builder.line = rhs_node.location.first_line
            when Node::RuleRhs::Action
              builder.add_rhs(rhs_node)
            when Node::RuleRhs::Prec
              sym = find_symbol_by_id!(Grammar::Symbol::Id.from_token(rhs_node.token), location: rhs_node.location)
              builder.precedence_sym = sym
            else
              raise "Unknown Node: #{rhs_node}"
            end
          end

          builder.complete_input
          add_rule_builder(builder)
        when Grammar::Node::ParameterizedRule
          rhs_list = node.rhs_list.map do |rhs|
            builder = Grammar::Parameterized::Rhs.new

            rhs.each do |rhs_node|
              case rhs_node
              when Node::RuleRhs::Empty
              when Node::RuleRhs::Symbol
                builder.symbols << rhs_node
              when Node::RuleRhs::InstantiateRule
                builder.symbols << rhs_node
              when Node::RuleRhs::Action
                builder.action = rhs_node
              when Node::RuleRhs::Prec
                sym = find_symbol_by_id!(Grammar::Symbol::Id.from_token(rhs_node.token), location: rhs_node.location)
                builder.precedence_sym = sym
              else
                raise "Unknown Node: #{rhs_node}"
              end
            end

            builder
          end

          rule = Grammar::Parameterized::Rule.new(node.name, node.parameters, rhs_list, tag: node.tag, is_inline: node.is_inline)
          add_parameterized_rule(rule)
        else
          raise "Unknown Node: #{node}"
        end
      end
    end

    # @rbs () -> void
    def validate_pslr_lexer!
      value = @define['api.pslr.lexer']
      return if value.nil? || value.empty?

      unless value == 'generated'
        raise %(%define api.pslr.lexer must be "generated", got "#{value}".)
      end

      unless pslr_defined?
        raise "%define api.pslr.lexer generated requires %define lr.type pslr."
      end
    end

    # @rbs () -> void
    def validate_pslr_tables!
      value = @define['pslr.tables']
      return if value.nil? || value.empty?
      return if %w[ielr canonical-lr].include?(value)

      raise %(%define pslr.tables must be "ielr" or "canonical-lr", got "#{value}".)
    end

    # @rbs (Lexer::Token::Base operand) -> Lexer::Token::Base
    def canonical_lexical_operand(operand)
      term = add_term(id: Grammar::Symbol::Id.from_token(operand), location: operand.location)
      return operand if term.name == operand.s_value

      Lexer::Token::Ident.new(s_value: term.name, location: operand.location)
    end

    # @rbs (Lexer::Token::Base operand) -> Array[Lexer::Token::Base]
    def expand_pslr_operand(operand)
      return @token_patterns.map(&:id) if operand.s_value == "yyall"
      return @symbol_sets.fetch(operand.s_value) if @symbol_sets.key?(operand.s_value)

      [canonical_lexical_operand(operand)]
    end

    # @rbs (Lexer::Token::Base operand) -> Grammar::LexTie::OperandGroup
    def pslr_operand_group(operand)
      if operand.s_value == "yyall"
        Grammar::LexTie::OperandGroup.new(names: @token_patterns.map(&:name), kind: :all)
      elsif @symbol_sets.key?(operand.s_value)
        Grammar::LexTie::OperandGroup.new(names: @symbol_sets.fetch(operand.s_value).map(&:s_value), kind: :set)
      else
        Grammar::LexTie::OperandGroup.new(names: [canonical_lexical_operand(operand).s_value], kind: :token)
      end
    end

    # @rbs (String key) -> Integer?
    def parse_pslr_positive_integer(key)
      value = @define[key]
      return nil if value.nil? || value.empty?

      parsed = Integer(value, 10)
      raise %(%define #{key} must be greater than 0, got "#{value}".) unless 0 < parsed

      parsed
    rescue ArgumentError
      raise %(%define #{key} must be an integer, got "#{value}".)
    end

    # @rbs (String key) -> Float?
    def parse_pslr_positive_float(key)
      value = @define[key]
      return nil if value.nil? || value.empty?

      parsed = Float(value)
      raise %(%define #{key} must be greater than or equal to 1.0, got "#{value}".) unless 1.0 <= parsed

      parsed
    rescue ArgumentError
      raise %(%define #{key} must be a number, got "#{value}".)
    end

    # @rbs () -> void
    def sort_precedence
      @precedences.sort_by! do |prec|
        prec.symbol.number
      end
      @precedences.freeze
    end

    # @rbs () -> Array[Grammar::Symbol]
    def compute_nullable
      @rules.each do |rule|
        case
        when rule.empty_rule?
          rule.nullable = true
        when rule.rhs.any?(&:term)
          rule.nullable = false
        else
          # noop
        end
      end

      while true do
        rs  = @rules.select {|e| e.nullable.nil? }
        nts = nterms.select {|e| e.nullable.nil? }
        rule_count_1  = rs.count
        nterm_count_1 = nts.count

        rs.each do |rule|
          if rule.rhs.all?(&:nullable)
            rule.nullable = true
          end
        end

        nts.each do |nterm|
          find_rules_by_symbol!(nterm).each do |rule|
            if rule.nullable
              nterm.nullable = true
            end
          end
        end

        rule_count_2  = @rules.count {|e| e.nullable.nil? }
        nterm_count_2 = nterms.count {|e| e.nullable.nil? }

        if (rule_count_1 == rule_count_2) && (nterm_count_1 == nterm_count_2)
          break
        end
      end

      rules.select {|r| r.nullable.nil? }.each do |rule|
        rule.nullable = false
      end

      nterms.select {|e| e.nullable.nil? }.each do |nterm|
        nterm.nullable = false
      end
    end

    # @rbs () -> Array[Grammar::Symbol]
    def compute_first_set
      terms.each do |term|
        term.first_set = Set.new([term]).freeze
        term.first_set_bitmap = Lrama::Bitmap.from_array([term.number])
      end

      nterms.each do |nterm|
        nterm.first_set = Set.new([]).freeze
        nterm.first_set_bitmap = Lrama::Bitmap.from_array([])
      end

      while true do
        changed = false

        @rules.each do |rule|
          rule.rhs.each do |r|
            if rule.lhs.first_set_bitmap | r.first_set_bitmap != rule.lhs.first_set_bitmap
              changed = true
              rule.lhs.first_set_bitmap = rule.lhs.first_set_bitmap | r.first_set_bitmap
            end

            break unless r.nullable
          end
        end

        break unless changed
      end

      nterms.each do |nterm|
        nterm.first_set = Lrama::Bitmap.to_array(nterm.first_set_bitmap).map do |number|
          find_symbol_by_number!(number)
        end.to_set
      end
    end

    # @rbs () -> Array[RuleBuilder]
    def setup_rules
      @rule_builders.each do |builder|
        builder.setup_rules
      end
    end

    # @rbs () -> Grammar::Symbol
    def append_special_symbols
      # YYEMPTY (token_id: -2, number: -2) is added when a template is evaluated
      # term = add_term(id: Token.new(Token::Ident, "YYEMPTY"), token_id: -2)
      # term.number = -2
      # @empty_symbol = term

      # YYEOF
      term = add_term(id: Grammar::Symbol::Id.new(name: "YYEOF", kind: :ident), alias_name: "\"end of file\"", token_id: 0)
      term.number = 0
      term.eof_symbol = true
      @eof_symbol = term

      # YYerror
      term = add_term(id: Grammar::Symbol::Id.new(name: "YYerror", kind: :ident), alias_name: "error")
      term.number = 1
      term.error_symbol = true
      @error_symbol = term

      # YYUNDEF
      term = add_term(id: Grammar::Symbol::Id.new(name: "YYUNDEF", kind: :ident), alias_name: "\"invalid token\"")
      term.number = 2
      term.undef_symbol = true
      @undef_symbol = term

      # $accept
      term = add_nterm(id: Grammar::Symbol::Id.new(name: "$accept", kind: :ident))
      term.accept_symbol = true
      @accept_symbol = term
    end

    # @rbs () -> void
    def resolve_inline_rules
      validate_inline_rules!

      while @rule_builders.any?(&:has_inline_rules?) do
        @rule_builders = @rule_builders.flat_map do |builder|
          if builder.has_inline_rules?
            Inline::Resolver.new(builder).resolve
          else
            builder
          end
        end
      end
    end

    # @rbs () -> void
    def validate_inline_rules!
      visiting = {} #: Hash[Parameterized::Rule, bool]
      visited = {} #: Hash[Parameterized::Rule, bool]

      parameterized_rules.select(&:inline?).each do |rule|
        validate_inline_rule!(rule, visiting, visited)
      end
    end

    # @rbs (Parameterized::Rule rule, Hash[Parameterized::Rule, bool] visiting, Hash[Parameterized::Rule, bool] visited) -> void
    def validate_inline_rule!(rule, visiting, visited)
      return if visited[rule]
      raise "Recursive inline rule: #{rule.name}" if visiting[rule]

      visiting[rule] = true
      rule.rhs.each do |rhs|
        rhs.symbols.each do |symbol|
          next if rule.parameters.any? { |parameter| parameter.s_value == symbol.name }

          inline_rule = @parameterized_resolver.find_inline(symbol)
          validate_inline_rule!(inline_rule, visiting, visited) if inline_rule
        end
      end
      visiting.delete(rule)
      visited[rule] = true
    end

    # @rbs () -> void
    def normalize_rules
      add_accept_rule
      setup_rules
      @rule_builders.each do |builder|
        builder.rules.each do |rule|
          add_nterm(id: rule._lhs, tag: rule.lhs_tag, location: rule._lhs_location)
          @rules << rule
        end
      end

      nterms.freeze
      @rules.sort_by!(&:id).freeze
    end

    # Add $accept rule to the top of rules
    def add_accept_rule
      raise "no rules in the input grammar" if @rule_builders.empty?

      if @start_nterm
        start = @start_nterm #: Lrama::Lexer::Token::Base
        @rules << Rule.new(
          id: @rule_counter.increment,
          _lhs: @accept_symbol.id,
          _rhs: [Grammar::Symbol::Id.from_token(start), @eof_symbol.id],
          _rhs_locations: [start.location, nil],
          token_code: nil,
          lineno: start.line
        )
      else
        rule_builder = @rule_builders.first #: RuleBuilder
        lineno = rule_builder.line
        lhs = rule_builder.lhs #: Grammar::Symbol::Id
        @rules << Rule.new(
          id: @rule_counter.increment,
          _lhs: @accept_symbol.id,
          _rhs: [lhs, @eof_symbol.id],
          _rhs_locations: [rule_builder.lhs_location, nil],
          token_code: nil,
          lineno: lineno
        )
      end
    end

    # Collect symbols from rules
    #
    # @rbs () -> void
    def collect_symbols
      @rules.flat_map(&:_rhs).each do |s|
        case s
        when Grammar::Symbol::Id
          add_term(id: s) if s.char?
        else
          raise "Unknown class: #{s}"
        end
      end

      terms.freeze
    end

    # @rbs () -> void
    def set_lhs_and_rhs
      @rules.each do |rule|
        rule.lhs = find_symbol_by_id!(rule._lhs, location: rule._lhs_location) if rule._lhs

        rule.rhs = rule._rhs.map.with_index do |t, index|
          find_symbol_by_id!(t, location: rule._rhs_locations&.[](index))
        end
      end
    end

    # @rbs () -> void
    def resolve_lexical_aliases
      return if @lexer_contexts.empty? && @symbol_sets.empty? && @lex_tie.declarations.empty?

      aliases = {} #: Hash[String, String]
      terms.each { |term| aliases[term.alias_name] = term.name if term.alias_name }
      return if aliases.empty?

      (@symbol_sets.values + @lexer_contexts.values.map(&:symbols)).each do |tokens|
        tokens.map! do |token|
          name = aliases[token.s_value]
          name ? Lexer::Token::Ident.new(s_value: name, location: token.location) : token
        end
      end

      @lex_tie.declarations.each do |decl|
        decl.groups.each { |group| group.names.map! { |name| aliases.fetch(name, name) } }
      end
    end

    # Rule inherits precedence from the last term in RHS.
    #
    # https://www.gnu.org/software/bison/manual/html_node/How-Precedence.html
    #
    # @rbs () -> void
    def fill_default_precedence
      @rules.each do |rule|
        # Explicitly specified precedence has the highest priority
        next if rule.precedence_sym

        precedence_sym = nil
        rule.rhs.each do |sym|
          precedence_sym = sym if sym.term?
        end

        rule.precedence_sym = precedence_sym
      end
    end

    # @rbs () -> Array[Grammar::Symbol]
    def fill_symbols
      fill_symbol_number
      fill_nterm_type(@types)
      fill_printer(@printers)
      fill_destructor(@destructors)
      fill_error_token(@error_tokens)
      sort_by_number!
    end

    # @rbs () -> Array[Rule]
    def fill_sym_to_rules
      @rules.each do |rule|
        key = rule.lhs.number
        @sym_to_rules[key] ||= []
        @sym_to_rules[key] << rule
      end
    end

    # @rbs () -> void
    def validate_no_precedence_for_nterm!
      errors = [] #: Array[String]

      nterms.each do |nterm|
        next if nterm.precedence.nil?

        errors << "[BUG] Precedence #{nterm.name} (line: #{nterm.precedence.lineno}) is defined for nonterminal symbol (line: #{@symbols_resolver.nterm_location(nterm)&.first_line}). Precedence can be defined for only terminal symbol."
      end

      return if errors.empty?

      raise errors.join("\n")
    end

    # @rbs () -> void
    def validate_rule_lhs_is_nterm!
      errors = [] #: Array[String]

      rules.each do |rule|
        next if rule.lhs.nterm?

        errors << "[BUG] LHS of #{rule.display_name} (line: #{rule.lineno}) is terminal symbol. It should be nonterminal symbol."
      end

      return if errors.empty?

      raise errors.join("\n")
    end

    # # @rbs () -> void
    def validate_duplicated_precedence!
      errors = [] #: Array[String]
      seen = {} #: Hash[Grammar::Symbol, Precedence]

      precedences.each do |prec|
        symbol = prec.symbol
        if first = seen[symbol]
          errors << "%#{prec.type} redeclaration for #{symbol.name} (line: #{prec.lineno}) previous declaration was %#{first.type} (line: #{first.lineno})"
        else
          seen[symbol] = prec
        end
      end

      return if errors.empty?

      raise errors.join("\n")
    end

    # @rbs () -> void
    def set_locations
      @locations = @locations || @rules.any? {|rule| rule.contains_at_reference? }
    end
  end
end

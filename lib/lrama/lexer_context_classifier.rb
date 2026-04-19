# rbs_inline: enabled
# frozen_string_literal: true

module Lrama
  # Classifies parser states into lexer context categories.
  #
  # When LALR states are merged, states from different grammatical contexts
  # (e.g., BEG vs CMDARG) share the same state number, making them
  # indistinguishable to the lexer. This classifier analyzes kernel items
  # to determine the lexer context of each state, enabling context-aware
  # state splitting.
  #
  # Context definitions come from %lexer-context directives in the grammar file.
  # Each directive maps a context name to a set of symbols:
  #
  #   %lexer-context BEG keyword_if keyword_unless '(' '[' '{'
  #   %lexer-context CMDARG tIDENTIFIER tFID tCONSTANT
  #
  class LexerContextClassifier
    # @rbs (Hash[String, Grammar::LexerContext] lexer_contexts, ?Hash[String, Array[String]] expansion_args) -> void
    def initialize(lexer_contexts, expansion_args = {})
      @lexer_contexts = lexer_contexts
      @expansion_args = expansion_args
      @symbol_to_context = build_symbol_to_context_map
      @context_names = build_context_names
    end

    # Classify a state's kernel items into context groups.
    #
    # @rbs (State state) -> Hash[Integer, Array[State::Item]]
    def classify(state)
      groups = {}

      state.kernels.each do |item|
        ctx = infer_item_context(item)
        groups[ctx] ||= []
        groups[ctx] << item
      end

      groups
    end

    # Infer the lexer context for a single kernel item.
    #
    # @rbs (State::Item item) -> Integer
    def infer_item_context(item)
      # Position 0 means we're at the start of a rule (just entered via GOTO)
      return default_beg_context if item.position == 0

      prev_sym = item.rhs[item.position - 1]
      classify_symbol_context(prev_sym)
    end

    # Classify context based on the symbol before the dot.
    #
    # @rbs (Grammar::Symbol sym) -> Integer
    def classify_symbol_context(sym)
      name = sym.id.s_value
      # Also try without surrounding quotes for single-char tokens
      bare = name.gsub(/\A["']|["']\z/, "")

      # Direct match
      ctx = @symbol_to_context[name] || @symbol_to_context[bare]
      return ctx if ctx

      # Fallback: inherit context from parameterized rule expansion arguments
      if (arg_names = @expansion_args[name])
        arg_names.each do |arg_name|
          ctx = @symbol_to_context[arg_name]
          return ctx if ctx
        end
      end

      0
    end

    # For backward compatibility with states.rb split logic
    # @rbs (Grammar::Symbol sym) -> Integer
    def classify_terminal_context(sym)
      classify_symbol_context(sym)
    end

    # For backward compatibility with states.rb split logic
    # @rbs (Grammar::Symbol sym) -> Integer
    def classify_nonterminal_context(sym)
      classify_symbol_context(sym)
    end

    # Return a human-readable name for a context value.
    #
    # @rbs (Integer ctx) -> String
    def context_name(ctx)
      return "UNKNOWN" if ctx == 0

      names = @context_names.select { |flag, _| (ctx & flag) != 0 }.values
      names.empty? ? "UNKNOWN" : names.join("|")
    end

    # Class-level context_name for use without an instance (e.g., output.rb).
    # Requires lexer_contexts to build the name map.
    #
    # @rbs (Integer ctx, Hash[String, Grammar::LexerContext] lexer_contexts) -> String
    def self.context_name(ctx, lexer_contexts)
      return "UNKNOWN" if ctx == 0

      names = []
      lexer_contexts.each_value do |lc|
        names << lc.name if (ctx & lc.bitmask) != 0
      end
      names.empty? ? "UNKNOWN" : names.join("|")
    end

    # All context bitmasks OR'd together (for "is context known?" checks).
    # @rbs () -> Integer
    def all_contexts_mask
      mask = 0
      @lexer_contexts.each_value { |lc| mask |= lc.bitmask }
      mask
    end

    # Return the ordered list of context definitions.
    # @rbs () -> Array[Grammar::LexerContext]
    def contexts
      @lexer_contexts.values.sort_by(&:index)
    end

    private

    # Build a map from symbol name → context bitmask.
    # @rbs () -> Hash[String, Integer]
    def build_symbol_to_context_map
      map = {}
      @lexer_contexts.each_value do |lc|
        lc.symbols.each do |sym|
          name = sym.s_value
          # OR the bitmask in case a symbol appears in multiple contexts
          map[name] = (map[name] || 0) | lc.bitmask
        end
      end
      map
    end

    # Build a map from bitmask value → context name.
    # @rbs () -> Hash[Integer, String]
    def build_context_names
      names = {}
      @lexer_contexts.each_value do |lc|
        names[lc.bitmask] = lc.name
      end
      names
    end

    # Return the bitmask for the first defined context (used as default for position-0 items).
    # Returns 0 if no contexts are defined.
    # @rbs () -> Integer
    def default_beg_context
      first = @lexer_contexts.values.min_by(&:index)
      first ? first.bitmask : 0
    end
  end
end

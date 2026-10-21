# frozen_string_literal: true

require "forwardable"
require_relative "tracer/duration"

module Lrama
  class Output
    extend Forwardable
    include Tracer::Duration

    attr_reader :grammar_file_path, :context, :grammar, :error_recovery, :include_header

    def_delegators "@context", :yyfinal, :yylast, :yyntokens, :yynnts, :yynrules, :yynstates,
                               :yymaxutok, :yypact_ninf, :yytable_ninf

    def_delegators "@grammar", :eof_symbol, :error_symbol, :undef_symbol, :accept_symbol

    def initialize(
      out:, output_file_path:, template_name:, grammar_file_path:,
      context:, grammar:, header_out: nil, header_file_path: nil, error_recovery: false
    )
      @out = out
      @output_file_path = output_file_path
      @template_name = template_name
      @grammar_file_path = grammar_file_path
      @header_out = header_out
      @header_file_path = header_file_path
      @context = context
      @grammar = grammar
      @error_recovery = error_recovery
      @include_header = header_file_path ? header_file_path.sub("./", "") : nil
    end

    if ERB.instance_method(:initialize).parameters.last.first == :key
      def self.erb(input)
        ERB.new(input, trim_mode: '-')
      end
    else
      def self.erb(input)
        ERB.new(input, nil, '-')
      end
    end

    def render_partial(file)
      ERB.render(partial_file(file), context: @context, output: self)
    end

    def render
      report_duration(:render) do
        tmp = eval_template(template_file, @output_file_path)
        @out << tmp

        if @header_file_path
          tmp = eval_template(header_template_file, @header_file_path)

          if @header_out
            @header_out << tmp
          else
            File.write(@header_file_path, tmp)
          end
        end
      end
    end

    # A part of b4_token_enums
    def token_enums
      @context.yytokentype.map do |s_value, token_id, display_name|
        s = sprintf("%s = %d%s", s_value, token_id, token_id == yymaxutok ? "" : ",")

        if display_name
          sprintf("    %-30s /* %s  */\n", s, display_name)
        else
          sprintf("    %s\n", s)
        end
      end.join
    end

    # b4_symbol_enum
    def symbol_enum
      last_sym_number = @context.yysymbol_kind_t.last[1]
      @context.yysymbol_kind_t.map do |s_value, sym_number, display_name|
        s = sprintf("%s = %d%s", s_value, sym_number, (sym_number == last_sym_number) ? "" : ",")

        if display_name
          sprintf("  %-40s /* %s  */\n", s, display_name)
        else
          sprintf("  %s\n", s)
        end
      end.join
    end

    def yytranslate
      int_array_to_string(@context.yytranslate)
    end

    def yytranslate_inverted
      int_array_to_string(@context.yytranslate_inverted)
    end

    def yyrline
      int_array_to_string(@context.yyrline)
    end

    def yytname
      string_array_to_string(@context.yytname) + " YY_NULLPTR"
    end

    # b4_int_type_for
    def int_type_for(ary)
      min = ary.min
      max = ary.max

      case
      when (-127 <= min && min <= 127) && (-127 <= max && max <= 127)
        "yytype_int8"
      when (0 <= min && min <= 255) && (0 <= max && max <= 255)
        "yytype_uint8"
      when (-32767 <= min && min <= 32767) && (-32767 <= max && max <= 32767)
        "yytype_int16"
      when (0 <= min && min <= 65535) && (0 <= max && max <= 65535)
        "yytype_uint16"
      else
        "int"
      end
    end

    def symbol_actions_for_printer
      @grammar.symbols.map do |sym|
        next unless sym.printer

        <<-STR
    case #{sym.enum_name}: /* #{sym.comment}  */
#line #{sym.printer.lineno} "#{@grammar_file_path}"
         {#{sym.printer.translated_code(sym.tag)}}
#line [@oline@] [@ofile@]
        break;

        STR
      end.join
    end

    def symbol_actions_for_destructor
      @grammar.symbols.map do |sym|
        next unless sym.destructor

        <<-STR
    case #{sym.enum_name}: /* #{sym.comment}  */
#line #{sym.destructor.lineno} "#{@grammar_file_path}"
         {#{sym.destructor.translated_code(sym.tag)}}
#line [@oline@] [@ofile@]
        break;

        STR
      end.join
    end

    # b4_user_initial_action
    def user_initial_action(comment = "")
      return "" unless @grammar.initial_action

      <<-STR
        #{comment}
#line #{@grammar.initial_action.line} "#{@grammar_file_path}"
        {#{@grammar.initial_action.translated_code}}
      STR
    end

    def after_shift_function(comment = "")
      return "" unless @grammar.after_shift

      <<-STR
        #{comment}
#line #{@grammar.after_shift.line} "#{@grammar_file_path}"
        {#{@grammar.after_shift.s_value}(#{parse_param_name});}
#line [@oline@] [@ofile@]
      STR
    end

    def before_reduce_function(comment = "")
      return "" unless @grammar.before_reduce

      <<-STR
        #{comment}
#line #{@grammar.before_reduce.line} "#{@grammar_file_path}"
        {#{@grammar.before_reduce.s_value}(yylen#{user_args});}
#line [@oline@] [@ofile@]
      STR
    end

    def after_reduce_function(comment = "")
      return "" unless @grammar.after_reduce

      <<-STR
        #{comment}
#line #{@grammar.after_reduce.line} "#{@grammar_file_path}"
        {#{@grammar.after_reduce.s_value}(yylen#{user_args});}
#line [@oline@] [@ofile@]
      STR
    end

    def after_shift_error_token_function(comment = "")
      return "" unless @grammar.after_shift_error_token

      <<-STR
        #{comment}
#line #{@grammar.after_shift_error_token.line} "#{@grammar_file_path}"
        {#{@grammar.after_shift_error_token.s_value}(#{parse_param_name});}
#line [@oline@] [@ofile@]
      STR
    end

    def after_pop_stack_function(len, comment = "")
      return "" unless @grammar.after_pop_stack

      <<-STR
        #{comment}
#line #{@grammar.after_pop_stack.line} "#{@grammar_file_path}"
        {#{@grammar.after_pop_stack.s_value}(#{len}#{user_args});}
#line [@oline@] [@ofile@]
      STR
    end

    def symbol_actions_for_error_token
      @grammar.symbols.map do |sym|
        next unless sym.error_token

        <<-STR
    case #{sym.enum_name}: /* #{sym.comment}  */
#line #{sym.error_token.lineno} "#{@grammar_file_path}"
         {#{sym.error_token.translated_code(sym.tag)}}
#line [@oline@] [@ofile@]
        break;

        STR
      end.join
    end

    # b4_user_actions
    def user_actions
      action = @context.states.rules.map do |rule|
        next unless rule.token_code

        code = rule.token_code
        spaces = " " * (code.column - 1)

        <<-STR
  case #{rule.id + 1}: /* #{rule.as_comment}  */
#line #{code.line} "#{@grammar_file_path}"
#{spaces}{#{rule.translated_code(@grammar)}}
#line [@oline@] [@ofile@]
    break;

        STR
      end.join

      action + <<-STR

#line [@oline@] [@ofile@]
      STR
    end

    def omit_blanks(param)
      param.strip
    end

    # b4_parse_param
    def parse_param
      if @grammar.parse_param
        omit_blanks(@grammar.parse_param)
      else
        ""
      end
    end

    def lex_param
      if @grammar.lex_param
        omit_blanks(@grammar.lex_param)
      else
        ""
      end
    end

    # b4_user_formals
    def user_formals
      if @grammar.parse_param
        ", #{parse_param}"
      else
        ""
      end
    end

    # b4_user_args
    def user_args
      if @grammar.parse_param
        ", #{parse_param_name}"
      else
        ""
      end
    end

    def extract_param_name(param)
      param[/\b([a-zA-Z0-9_]+)(?=\s*\z)/]
    end

    def parse_param_name
      if @grammar.parse_param
        extract_param_name(parse_param)
      else
        ""
      end
    end

    def lex_param_name
      if @grammar.lex_param
        extract_param_name(lex_param)
      else
        ""
      end
    end

    # b4_parse_param_use
    def parse_param_use(val, loc)
      str = <<-STR.dup
  YY_USE (#{val});
  YY_USE (#{loc});
      STR

      if @grammar.parse_param
        str << "  YY_USE (#{parse_param_name});"
      end

      str
    end

    # b4_yylex_formals
    def yylex_formals
      ary = ["&yylval"]
      ary << "&yylloc" if @grammar.locations

      if @grammar.lex_param
        ary << lex_param_name
      end

      "(#{ary.join(', ')})"
    end

    # b4_table_value_equals
    def table_value_equals(table, value, literal, symbol)
      if literal < table.min || table.max < literal
        "0"
      else
        "((#{value}) == #{symbol})"
      end
    end

    # b4_yyerror_args
    def yyerror_args
      ary = ["&yylloc"]

      if @grammar.parse_param
        ary << parse_param_name
      end

      "#{ary.join(', ')}"
    end

    def template_basename
      File.basename(template_file)
    end

    def aux
      @grammar.aux
    end

    def int_array_to_string(ary)
      last = ary.count - 1

      ary.each_with_index.each_slice(10).map do |slice|
        "  " + slice.map { |e, i| sprintf("%6d%s", e, (i == last) ? "" : ",") }.join
      end.join("\n")
    end

    def spec_mapped_header_file
      @header_file_path
    end

    def b4_cpp_guard__b4_spec_mapped_header_file
      if @header_file_path
        "YY_YY_" + @header_file_path.gsub(/[^a-zA-Z_0-9]+/, "_").upcase + "_INCLUDED"
      else
        ""
      end
    end

    # b4_percent_code_get
    def percent_code(name)
      @grammar.percent_codes.select do |percent_code|
        percent_code.name == name
      end.map do |percent_code|
        percent_code.code
      end.join
    end

    # PSLR Output Helper Methods
    # Based on PSLR::OutputHelper - generates PSLR-specific C code

    # Check if the grammar requested PSLR output.
    def pslr_enabled?
      @grammar.pslr_defined?
    end

    # Check if LAC (lookahead correction) is enabled.
    # Defaults to full for PSLR parsers; any parser type can opt in
    # with %define parse.lac full (section 3.5.2 is orthogonal to PSLR).
    def lac_enabled?
      @grammar.parse_lac_full?
    end

    # Pure mode: the generated parser owns lexical analysis
    # (%define api.pslr.lexer generated).
    def pslr_pure_mode?
      pslr_enabled? && @grammar.pslr_lexer_generated?
    end

    # Check if PSLR scanner tables are available.
    def pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa
      !scanner_fsa.nil? && !scanner_fsa.states.empty?
    end

    def pslr_function_declarations
      return "" unless pslr_enabled?

      declarations = ["#include <stddef.h>"]

      if pslr_scanner_enabled?
        declarations << <<~C_CODE
          #ifndef YYPSLR_SCAN_RESULT_DEFINED
          # define YYPSLR_SCAN_RESULT_DEFINED
          typedef struct yypslr_scan_result {
            int token;
            int length;
            int is_layout;
            int is_character_token;
            int from_fallback;
          } yypslr_scan_result;
          #endif

          int yy_pseudo_scan_result (int parser_state, const char *input, size_t input_len, yypslr_scan_result *result);
          int yy_pseudo_scan (int parser_state, const char *input, size_t input_len, int *match_length);
          int yy_pslr_token_is_layout (int token);
        C_CODE

        declarations << <<~C_CODE
          #define YYPSLR_ENABLED 1
          #define YYPSLR_NO_MATCH YYEMPTY

          #ifndef YYPSLR_PSEUDO_SCAN_STATE
          # define YYPSLR_PSEUDO_SCAN_STATE(ParserState, Input, InputLen, MatchLength) \\
            yy_pseudo_scan ((ParserState), (Input), (InputLen), (MatchLength))
          #endif

          #ifndef YYPSLR_PSEUDO_SCAN_RESULT_STATE
          # define YYPSLR_PSEUDO_SCAN_RESULT_STATE(ParserState, Input, InputLen, Result) \\
            yy_pseudo_scan_result ((ParserState), (Input), (InputLen), (Result))
          #endif

          #ifndef YYPSLR_TOKEN_IS_LAYOUT
          # define YYPSLR_TOKEN_IS_LAYOUT(Token) yy_pslr_token_is_layout ((Token))
          #endif

          int yypslr_scan_with_layout (int yyparser_state, const char **yyinput,
                                       size_t *yyinput_len, YYSTYPE *yylvalp,
                                       yypslr_scan_result *yyresult#{lex_param.empty? ? "" : ", #{lex_param}"});

          #ifndef YYPSLR_SCAN_WITH_LAYOUT
          # define YYPSLR_SCAN_WITH_LAYOUT(yyParserState, yyInputPtr, yyInputLenPtr, yyLvalPtr, yyResult) \\
            yypslr_scan_with_layout ((yyParserState), (yyInputPtr), (yyInputLenPtr), (yyLvalPtr), (yyResult)#{lex_param.empty? ? "" : ", #{lex_param_name}"})
          #endif
        C_CODE
      end

      if pslr_pure_mode?
        declarations << <<~C_CODE
          /* Pure mode (%define api.pslr.lexer generated): the generated
             parser owns lexical analysis. Give it the input before
             calling yyparse. */
          void yypslr_set_input (const char *input, size_t input_len);
        C_CODE
      end

      if (member = pslr_state_member)
        declarations << <<~C_CODE
          #ifndef YYGETSTATE_CONTEXT
          # define YYGETSTATE_CONTEXT(Context) ((Context)->#{member})
          #endif
        C_CODE

        if pslr_scanner_enabled?
          declarations << <<~C_CODE
            #ifndef YYPSLR_PSEUDO_SCAN
            # define YYPSLR_PSEUDO_SCAN(Context, Input, InputLen, MatchLength) \\
              ((Context) != 0 \\
               ? YYPSLR_PSEUDO_SCAN_STATE (YYGETSTATE_CONTEXT (Context), (Input), (InputLen), (MatchLength)) \\
               : YYEMPTY)
            #endif

            #ifndef YYPSLR_PSEUDO_SCAN_RESULT
            # define YYPSLR_PSEUDO_SCAN_RESULT(Context, Input, InputLen, Result) \\
              ((Context) != 0 \\
               ? YYPSLR_PSEUDO_SCAN_RESULT_STATE (YYGETSTATE_CONTEXT (Context), (Input), (InputLen), (Result)) \\
               : YYEMPTY)
            #endif
          C_CODE
        end

        if !parse_param_name.empty?
          declarations << <<~C_CODE
            #ifndef YYSETSTATE_CONTEXT
            # define YYSETSTATE_CONTEXT(CurrentState) \\
              do { \\
                if (#{parse_param_name} != 0) { \\
                  YYGETSTATE_CONTEXT (#{parse_param_name}) = (CurrentState); \\
                } \\
              } while (0)
            #endif
          C_CODE
        end
      end

      declarations.join("\n")
    end

    def pslr_state_member
      member = @grammar.pslr_state_member
      member&.strip
    end

    def pslr_accepting_states
      return [] unless pslr_scanner_enabled?

      @context.states.scanner_fsa.states.select(&:accepting?)
    end

    def pslr_token_pattern_count
      @context.states.token_patterns.size
    end

    def pslr_token_id(token_pattern)
      @context.states.find_symbol_by_s_value!(token_pattern.name).token_id
    end

    # Generate Scanner FSA transition table as C code
    def scanner_transition_table
      return "" unless pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa

      lines = []
      lines << "/* Scanner FSA transition table */"
      lines << "#define YY_SCANNER_NUM_STATES #{scanner_fsa.states.size}"
      lines << "#define YY_SCANNER_INVALID_STATE (-1)"
      lines << ""
      lines << "static const int yy_scanner_transition[YY_SCANNER_NUM_STATES][256] = {"

      scanner_fsa.states.each_with_index do |state, idx|
        transitions = Array.new(256, -1)
        state.transitions.each do |char, target_id|
          transitions[char.ord] = target_id
        end
        lines << "  /* state #{idx} */ {#{transitions.join(', ')}}#{idx < scanner_fsa.states.size - 1 ? ',' : ''}"
      end

      lines << "};"
      lines.join("\n")
    end

    # Generate state_to_accepting table as C code
    def state_to_accepting_table
      return "" unless pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa
      accepting_indices = Array.new(scanner_fsa.states.size, -1)

      pslr_accepting_states.each_with_index do |state, index|
        accepting_indices[state.id] = index
      end

      lines = []
      lines << ""
      lines << "/* FSA state -> accepting state index mapping */"
      lines << "#define YY_ACCEPTING_NONE (-1)"
      lines << ""
      lines << "static const int yy_state_to_accepting[YY_SCANNER_NUM_STATES] = {"
      lines << "  #{accepting_indices.join(', ')}"
      lines << "};"
      lines.join("\n")
    end

    def token_pattern_token_ids_table
      return "" unless pslr_scanner_enabled?

      lines = []
      lines << ""
      lines << "/* token pattern index -> parser token id */"
      lines << "#define YY_PSLR_EMPTY_PATTERN (-1)"
      lines << "#define YY_NUM_TOKEN_PATTERNS #{pslr_token_pattern_count}"
      lines << ""
      lines << "static const int yy_token_pattern_to_token_id[YY_NUM_TOKEN_PATTERNS] = {"
      lines << "  #{@context.states.token_patterns.map {|token_pattern| pslr_token_id(token_pattern) }.join(', ')}"
      lines << "};"
      lines << ""
      lines << "static const int yy_token_pattern_is_layout[YY_NUM_TOKEN_PATTERNS] = {"
      lines << "  #{@context.states.token_patterns.map {|token_pattern| token_pattern.layout? ? 1 : 0 }.join(', ')}"
      lines << "};"
      lines << ""
      lines << "int"
      lines << "yy_pslr_token_is_layout (int token)"
      lines << "{"
      lines << "  int i;"
      lines << "  for (i = 0; i < YY_NUM_TOKEN_PATTERNS; i++)"
      lines << "    if (yy_token_pattern_to_token_id[i] == token)"
      lines << "      return yy_token_pattern_is_layout[i];"
      lines << "  return 0;"
      lines << "}"
      lines.join("\n")
    end

    # Generate token IDs for accepting states as C code
    def accepting_tokens_table
      return "" unless pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa

      lines = []
      lines << ""
      lines << "/* Accepting state token IDs */"
      lines << ""

      # Collect all unique tokens
      all_tokens = @context.states.token_patterns.map(&:name)
      lines << "/* Token pattern names: #{all_tokens.join(', ')} */"
      lines << ""

      # Generate accepting tokens for each FSA state
      scanner_fsa.states.each do |state|
        next unless state.accepting?

        token_names = state.accepting_tokens.map(&:name)
        lines << "/* State #{state.id} accepts: #{token_names.join(', ')} */"
      end

      lines.join("\n")
    end

    # Generate scanner_accepts table as C code
    def scanner_accepts_table_code
      return "" unless pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa
      scanner_accepts = @context.states.scanner_accepts_table
      return "" unless scanner_accepts

      lines = []
      lines << ""
      lines << "/* scanner_accepts[parser_state][accepting_state] -> token pattern index */"
      lines << "/* YY_PSLR_EMPTY_PATTERN means no token accepted */"
      lines << ""

      num_parser_states = @context.states.states.size
      num_accepting_states = pslr_accepting_states.size

      lines << "#define YY_NUM_PARSER_STATES #{num_parser_states}"
      lines << "#define YY_NUM_ACCEPTING_STATES #{num_accepting_states}"
      lines << ""

      if num_accepting_states > 0
        lines << "static const int yy_scanner_accepts[YY_NUM_PARSER_STATES][YY_NUM_ACCEPTING_STATES] = {"
        token_pattern_indexes = @context.states.token_patterns.each_with_index.to_h

        @context.states.states.each_with_index do |parser_state, ps_idx|
          row = []
          pslr_accepting_states.each do |fsa_state|
            token = scanner_accepts[parser_state.id, fsa_state.id]
            if token
              row << token_pattern_indexes.fetch(token)
            else
              row << -1
            end
          end

          lines << "  /* parser state #{ps_idx} */ {#{row.join(', ')}}#{ps_idx < num_parser_states - 1 ? ',' : ''}"
        end

        lines << "};"
        lines << ""
        lines << "#define YY_NUM_FALLBACK_PROFILES #{scanner_accepts.fallback_profiles.size}"
        lines << "static const int yy_scanner_fallback_accepts[YY_NUM_FALLBACK_PROFILES][YY_NUM_ACCEPTING_STATES] = {"
        scanner_accepts.fallback_profiles.each do |profile|
          row = pslr_accepting_states.map do |fsa_state|
            transition = profile[fsa_state.id]
            token = transition && transition.last
            token ? token_pattern_indexes.fetch(token) : -1
          end
          lines << "  {#{row.join(', ')}},"
        end
        lines << "};"
        lines << "static const int yy_scanner_fallback_next[YY_NUM_FALLBACK_PROFILES][YY_NUM_ACCEPTING_STATES] = {"
        scanner_accepts.fallback_profiles.each do |profile|
          row = pslr_accepting_states.map do |fsa_state|
            transition = profile[fsa_state.id]
            transition ? transition.first : -1
          end
          lines << "  {#{row.join(', ')}},"
        end
        lines << "};"
        lines << scanner_continuation_table_code
      end

      lines.join("\n")
    end

    def scanner_continuation_table_code
      scanner_fsa = @context.states.scanner_fsa
      scanner_accepts = @context.states.scanner_accepts_table
      patterns = @context.states.token_patterns
      accepting_states = pslr_accepting_states
      relations = scanner_fsa.states.map {|state| [state.id, state.transitions.values.uniq] }.to_h
      accepting_bits = scanner_fsa.states.map {|state| [state.id, 0] }.to_h
      accepting_states.each_with_index {|state, index| accepting_bits[state.id] = 1 << index }
      reachable = Digraph.new(relations.keys, relations, accepting_bits).compute
      future = scanner_fsa.states.map do |state|
        relations.fetch(state.id).inject(0) {|bits, target| bits | reachable.fetch(target) }
      end

      # Rows share a profile when the same future accepting states can replace the winner.
      profiles = {}
      normal_profiles = @context.states.states.map do |parser_state|
        [nil, *patterns].map do |winner|
          mask = 0
          accepting_states.each_with_index do |state, index|
            token = scanner_accepts[parser_state.id, state.id]
            if token && (!winner || @context.states.length_precedences.normal_precedes?(winner.name, token.name))
              mask |= 1 << index
            end
          end
          profiles[mask] ||= profiles.size
        end
      end

      lines = ["/* Continue only while a future match can replace the selected token. */"]
      lines << "static const int yy_scanner_normal_profile[YY_NUM_PARSER_STATES][YY_NUM_TOKEN_PATTERNS + 1] = {"
      normal_profiles.each {|row| lines << "  {#{row.join(', ')}}," }
      lines << "};"
      lines << "static const unsigned char yy_scanner_continue[#{profiles.size}][YY_SCANNER_NUM_STATES] = {"
      profiles.each_key do |mask|
        lines << "  {#{future.map {|bits| (bits & mask).zero? ? 0 : 1 }.join(', ')}},"
      end
      lines << "};"
      lines << "static const unsigned char yy_scanner_fallback_continue[YY_NUM_FALLBACK_PROFILES][YY_SCANNER_NUM_STATES] = {"
      scanner_fallback_continuations.each {|row| lines << "  {#{row.join(', ')}}," }
      lines << "};"
      lines.join("\n")
    end

    def scanner_fallback_continuations
      scanner_fsa = @context.states.scanner_fsa
      profiles = @context.states.scanner_accepts_table.fallback_profiles
      initial = [0, 0]
      nodes = [initial]
      visited = Set.new(nodes)
      relations = {}
      updates = {}
      nodes.each do |node|
        profile_id, state_id = node
        updates[node] = 0
        relations[node] = scanner_fsa.states[state_id].transitions.values.uniq.map do |target_id|
          transition = profiles[profile_id][target_id]
          updates[node] = 1 if transition && transition.last
          target = [transition ? transition.first : profile_id, target_id]
          nodes << target if visited.add?(target)
          target
        end
      end
      reachable_updates = Digraph.new(nodes, relations, updates).compute
      profiles.each_index.map do |profile_id|
        scanner_fsa.states.map {|state| reachable_updates.fetch([profile_id, state.id], 0) }
      end
    end

    # Generate length_precedences table as C code
    def length_precedences_table_code
      return "" unless pslr_scanner_enabled?
      length_precedences = @context.states.length_precedences
      return "" unless length_precedences

      lines = []
      lines << ""
      lines << "/* yy_pslr_length_precedes[old_token][new_token] is true when a longer"
      lines << "   match for new_token replaces an earlier match for old_token. */"
      lines << ""

      num_tokens = pslr_token_pattern_count
      if num_tokens > 0
        lines << length_precedence_matrix_code(
          "yy_pslr_length_precedes",
          num_tokens,
          :normal_precedes?
        )
      end

      lines.join("\n")
    end

    def length_precedence_matrix_code(table_name, num_tokens, query_method)
      length_precedences = @context.states.length_precedences
      lines = []

      lines << "static const int #{table_name}[#{num_tokens}][#{num_tokens}] = {"
      @context.states.token_patterns.each_with_index do |t1, i|
        row = @context.states.token_patterns.map do |t2|
          length_precedences.public_send(query_method, t1.name, t2.name) ? 1 : 0
        end
        lines << "  /* #{t1.name} */ {#{row.join(', ')}}#{i < num_tokens - 1 ? ',' : ''}"
      end
      lines << "};"

      lines.join("\n")
    end

    def pslr_lac_function
      return "" unless lac_enabled?

      <<~C_CODE

        static int
        yy_lac_check_ (yy_state_t *yyss, yy_state_t *yyssp, yysymbol_kind_t yytoken)
        {
          yy_state_t yylac_states[YYINITDEPTH];
          yy_state_t *yylac_base = yylac_states;
          YYPTRDIFF_T yylac_size = YYINITDEPTH;
          YYPTRDIFF_T yylac_len = 0;
          int yylac_status = 0;

          if (YYMAXDEPTH < yyssp - yyss + 1)
            return YYENOMEM;

          for (;;)
            {
              int yystate = yylac_len ? yylac_base[yylac_len - 1] : *yyssp;
              int yyn = yypact[yystate];

              if (!yypact_value_is_default (yyn))
                {
                  yyn += yytoken;
                  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == yytoken)
                    {
                      yyn = yytable[yyn];
                      if (0 < yyn)
                        {
                          yylac_status = 1;
                          break;
                        }
                      if (yytable_value_is_error (yyn))
                        break;
                      yyn = -yyn;
                    }
                  else
                    {
                      yyn = yydefact[yystate];
                      if (yyn == 0)
                        break;
                    }
                }
              else
                {
                  yyn = yydefact[yystate];
                  if (yyn == 0)
                    break;
                }

              /* Keep the parser's stack read-only; only speculative states need storage. */
              if (yylac_len < yyr2[yyn])
                {
                  yyssp -= yyr2[yyn] - yylac_len;
                  yylac_len = 0;
                }
              else
                yylac_len -= yyr2[yyn];
              {
                const int yylhs = yyr1[yyn] - YYNTOKENS;
                const int yytop = yylac_len ? yylac_base[yylac_len - 1] : *yyssp;
                const int yyi = yypgoto[yylhs] + yytop;
                yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == yytop
                           ? yytable[yyi]
                           : yydefgoto[yylhs]);
              }

              if (YYMAXDEPTH <= yyssp - yyss + 1 + yylac_len)
                {
                  yylac_status = YYENOMEM;
                  break;
                }
              if (yylac_len == yylac_size)
                {
                  yy_state_t *yylac_new;
                  yylac_size = yylac_size <= YYMAXDEPTH / 2 ? 2 * yylac_size : YYMAXDEPTH;
                  yylac_new = YY_CAST (yy_state_t *,
                    YYMALLOC (YY_CAST (YYSIZE_T, yylac_size * YYSIZEOF (yy_state_t))));
                  if (!yylac_new)
                    {
                      yylac_status = YYENOMEM;
                      break;
                    }
                  YYCOPY (yylac_new, yylac_base, yylac_len);
                  if (yylac_base != yylac_states)
                    YYFREE (yylac_base);
                  yylac_base = yylac_new;
                }

              yylac_base[yylac_len++] = YY_CAST (yy_state_t, yystate);
            }
          if (yylac_base != yylac_states)
            YYFREE (yylac_base);
          return yylac_status;
        }
      C_CODE
    end

    # Generate pseudo_scan function as C code
    def pseudo_scan_function
      return "" unless pslr_scanner_enabled?

      <<~C_CODE

        /*
         * pseudo_scan: PSLR(1) scanning function
         * Based on Definition 3.2.16 from the PSLR dissertation,
         * extended with the fallback row of section 3.5.1.
         *
         * Input:
         *   parser_state: Current parser state
         *   input: Unconsumed input pointer (may contain NUL bytes)
         *   input_len: Number of remaining input bytes
         *   result: Output parameter for the match
         *
         * Returns: Selected parser token ID. #{eof_symbol.id.s_value} when input_len is zero.
         * If neither the parser-state row nor the fallback row matches,
         * returns YYUNDEF and consumes one byte (character-token handling);
         * from_fallback is set for both cases because a syntax error is
         * then guaranteed.
         */
        int
        yy_pseudo_scan_result (int parser_state, const char *input, size_t input_len, yypslr_scan_result *result)
        {
          int ss = 0;  /* FSA initial state */
          int ibest = 0;
          int pbest = YY_PSLR_EMPTY_PATTERN;
          int fallback_ibest = 0;
          int fallback_pbest = YY_PSLR_EMPTY_PATTERN;
          int fallback_profile = 0;
          size_t i = 0;

          if (result == NULL) {
            return YYEMPTY;
          }

          result->token = YYEMPTY;
          result->length = 0;
          result->is_layout = 0;
          result->is_character_token = 0;
          result->from_fallback = 0;

          if (parser_state < 0 || parser_state >= YY_NUM_PARSER_STATES || input == NULL) {
            return YYEMPTY;
          }

          if (input_len == 0) {
            result->token = #{eof_symbol.id.s_value};
            return result->token;
          }

          while (i < input_len) {
            int c = (unsigned char)input[i];
            int next_ss = yy_scanner_transition[ss][c];

            if (next_ss == YY_SCANNER_INVALID_STATE) {
              break;
            }

            ss = next_ss;
            i++;

            /* Check if this is an accepting state */
            int sa = yy_state_to_accepting[ss];
            if (sa != YY_ACCEPTING_NONE) {
              int pattern_index = yy_scanner_accepts[parser_state][sa];
              if (pattern_index != YY_PSLR_EMPTY_PATTERN) {
                if (pbest == YY_PSLR_EMPTY_PATTERN ||
                    yy_pslr_length_precedes[pbest][pattern_index]) {
                  pbest = pattern_index;
                  ibest = (int)i;
                }
              }

              pattern_index = yy_scanner_fallback_accepts[fallback_profile][sa];
              fallback_profile = yy_scanner_fallback_next[fallback_profile][sa];
              if (pattern_index != YY_PSLR_EMPTY_PATTERN) {
                fallback_pbest = pattern_index;
                fallback_ibest = (int)i;
              }
            }

            if (!yy_scanner_continue[yy_scanner_normal_profile[parser_state][pbest + 1]][ss] &&
                (pbest != YY_PSLR_EMPTY_PATTERN || !yy_scanner_fallback_continue[fallback_profile][ss])) {
              break;
            }
          }

          if (pbest != YY_PSLR_EMPTY_PATTERN) {
            result->token = yy_token_pattern_to_token_id[pbest];
            result->length = ibest;
            result->is_layout = yy_token_pattern_is_layout[pbest];
            return result->token;
          }

          if (fallback_pbest != YY_PSLR_EMPTY_PATTERN) {
            result->token = yy_token_pattern_to_token_id[fallback_pbest];
            result->length = fallback_ibest;
            result->is_layout = yy_token_pattern_is_layout[fallback_pbest];
            result->from_fallback = 1;
            return result->token;
          }

          result->token = YYUNDEF;
          result->length = 1;
          result->is_character_token = 1;
          result->from_fallback = 1;
          return result->token;
        }

        int
        yy_pseudo_scan(int parser_state, const char *input, size_t input_len, int *match_length)
        {
          yypslr_scan_result result;
          int token = yy_pseudo_scan_result (parser_state, input, input_len, &result);

          if (match_length != NULL) {
            *match_length = result.length;
          }

          return token;
        }
      C_CODE
    end

    # Check if lexer context table is available.
    def lexer_context_enabled?
      @context.states.lexer_context_enabled?
    end

    # Generate #define constants for lexer contexts, emitted early in the output
    # so that user code in %{ ... %} can reference them.
    def lexer_context_defines_code
      return "" unless lexer_context_enabled?

      classifier = @context.states.lexer_context_classifier
      lines = []
      lines << "/* Lexer context constants — generated from %lexer-context directives */"
      classifier.contexts.each do |lc|
        lines << "#define YY_CTX_%-8s 0x%02xULL" % [lc.name, lc.bitmask]
      end
      lines.join("\n")
    end

    # Generate the lexer context table as C code.
    def lexer_context_table_code
      return "" unless lexer_context_enabled?

      table = @context.states.lexer_context_table
      lexer_contexts = @grammar.lexer_contexts
      lines = []

      lines << "/* Lexer Context Classification Table */"
      lines << "/* Maps parser state -> lexer context flags */"
      lines << ""
      lines << "static const unsigned long long yy_lexer_context[] = {"

      table.each_with_index do |ctx, idx|
        ctx_name = LexerContextClassifier.context_name(ctx, lexer_contexts)
        comma = idx < table.size - 1 ? "," : ""
        lines << "  /* state #{idx} */ #{ctx}ULL#{comma} /* #{ctx_name} */"
      end

      lines << "};"
      lines << ""
      lines << "int"
      lines << "yy_lexer_context_is(int yystate, unsigned long long ctx_mask) {"
      lines << "    if (yystate < 0 || yystate >= #{table.size}) return 0;"
      lines << "    return (yy_lexer_context[yystate] & ctx_mask) != 0;"
      lines << "}"

      lines.join("\n")
    end

    # Check if token actions are defined
    def pslr_token_actions_enabled?
      pslr_enabled? && !@grammar.token_actions.empty?
    end

    # Generate layout accumulation declarations
    def pslr_layout_declarations
      return "" unless pslr_scanner_enabled? || pslr_pure_mode?

      <<~C_CODE

        #ifndef YYPSLR_LAYOUT_DEFINED
        # define YYPSLR_LAYOUT_DEFINED

        #include <limits.h>
        #include <string.h>

        typedef struct yypslr_layout {
          const char *text;
          int length;
        } yypslr_layout;

        # ifndef YYPSLR_LAYOUT_BUFFER_SIZE
        #  define YYPSLR_LAYOUT_BUFFER_SIZE 4096
        # endif

        static char yypslr_layout_initial[YYPSLR_LAYOUT_BUFFER_SIZE];
        static char *yypslr_layout_buffer = yypslr_layout_initial;
        static size_t yypslr_layout_capacity = sizeof yypslr_layout_initial;
        static int yypslr_layout_length = 0;

        static void
        yypslr_layout_clear (void)
        {
          if (yypslr_layout_buffer != yypslr_layout_initial)
            YYFREE (yypslr_layout_buffer);
          yypslr_layout_buffer = yypslr_layout_initial;
          yypslr_layout_capacity = sizeof yypslr_layout_initial;
          yypslr_layout_length = 0;
          yypslr_layout_buffer[0] = '\\0';
        }

        static int
        yypslr_layout_append (const char *text, int length)
        {
          size_t required;
          if (length < 0 || length > INT_MAX - yypslr_layout_length)
            return 0;

          required = (size_t) yypslr_layout_length + (size_t) length + 1;
          if (required > (size_t) YYSIZE_MAXIMUM)
            return 0;
          if (required > yypslr_layout_capacity)
            {
              size_t capacity = yypslr_layout_capacity;
              char *buffer;
              while (capacity < required)
                capacity = capacity > (size_t) YYSIZE_MAXIMUM / 2 ? required : capacity * 2;
              buffer = YY_CAST (char *, YYMALLOC (capacity));
              if (!buffer)
                return 0;
              memcpy (buffer, yypslr_layout_buffer, (size_t) yypslr_layout_length);
              if (yypslr_layout_buffer != yypslr_layout_initial)
                YYFREE (yypslr_layout_buffer);
              yypslr_layout_buffer = buffer;
              yypslr_layout_capacity = capacity;
            }

          memcpy (yypslr_layout_buffer + yypslr_layout_length, text, (size_t) length);
          yypslr_layout_length += length;
          yypslr_layout_buffer[yypslr_layout_length] = '\\0';
          return 1;
        }

        # define YYPSLR_LAYOUT_TEXT    yypslr_layout_buffer
        # define YYPSLR_LAYOUT_LENGTH  yypslr_layout_length
        # define YYPSLR_LAYOUT_CLEAR() yypslr_layout_clear ()
        # define YYPSLR_LAYOUT_APPEND(Text, Len) yypslr_layout_append ((Text), (Len))

        #endif /* YYPSLR_LAYOUT_DEFINED */
      C_CODE
    end

    # Generate token action dispatch function.
    # yylval inside a %token-action refers to the semantic value slot the
    # caller passes in, so token actions work with both the generated
    # (pure-mode) lexer and a user yylex driving the bridge macros.
    def pslr_token_action_function
      return "" unless pslr_token_actions_enabled?

      lines = []
      lines << ""
      lines << "/* PSLR token action dispatch */"
      lines << "/* Generated from %token-action declarations */"
      lines << ""
      lines << "#define yylval (*yylvalp)"
      lines << "static void"
      lines << "yypslr_token_action (int yytoken, const char *yytext, int yyleng, YYSTYPE *yylvalp#{lex_param.empty? ? "" : ", #{lex_param}"})"
      lines << "{"
      lines << "  YY_USE (yytext);"
      lines << "  YY_USE (yyleng);"
      lines << "  YY_USE (yylvalp);"
      lines << "  YY_USE (#{lex_param_name});" unless lex_param.empty?

      @grammar.token_actions.each_with_index do |action, idx|
        token_id = @context.states.find_symbol_by_s_value!(action.token_name).token_id
        keyword = idx == 0 ? "if" : "else if"
        lines << "  #{keyword} (yytoken == #{token_id})"
        lines << "    {"
        lines << "#line #{action.lineno} \"#{@grammar_file_path}\""
        lines << "      {#{action.code.s_value}}"
        lines << "#line [@oline@] [@ofile@]"
        lines << "    }"
      end

      lines << "}"
      lines << "#undef yylval"
      lines << ""
      lines << "#define YYPSLR_TOKEN_ACTION(yyToken, yyText, yyLen, yyLvalPtr) \\"
      lines << "  yypslr_token_action ((yyToken), (yyText), (yyLen), (yyLvalPtr)#{lex_param.empty? ? "" : ", #{lex_param_name}"})"
      lines.join("\n")
    end

    # Generate enhanced pseudo_scan_result with layout accumulation
    def pslr_layout_scan_function
      return "" unless pslr_scanner_enabled?

      <<~C_CODE

        /*
         * yypslr_scan_with_layout: scan with layout accumulation.
         *
         * Repeatedly invokes yy_pseudo_scan_result to consume input.
         * Layout tokens are accumulated in the layout buffer;
         * non-layout tokens are returned to the caller with the
         * accumulated layout available via YYPSLR_LAYOUT_TEXT.
         * The #{eof_symbol.id.s_value} token action (if any) runs before returning #{eof_symbol.id.s_value} so
         * trailing layout can be recovered (paper section 3.6).
         */
        int
        yypslr_scan_with_layout (int yyparser_state, const char **yyinput,
                                 size_t *yyinput_len, YYSTYPE *yylvalp,
                                 yypslr_scan_result *yyresult#{lex_param.empty? ? "" : ", #{lex_param}"})
        {
          YYPSLR_LAYOUT_CLEAR ();
          YY_USE (yylvalp);
        #{lex_param.empty? ? "" : "  YY_USE (#{lex_param_name});"}

          for (;;)
            {
              int yytoken = yy_pseudo_scan_result (yyparser_state, *yyinput, *yyinput_len, yyresult);

              if (yytoken == YYEMPTY)
                return yytoken;

              if (yytoken == #{eof_symbol.id.s_value})
                {
        #{pslr_token_actions_enabled? ? "          YYPSLR_TOKEN_ACTION (yytoken, *yyinput, 0, yylvalp);" : ""}
                  return yytoken;
                }

              if (yyresult->is_layout)
                {
                  if (!YYPSLR_LAYOUT_APPEND (*yyinput, yyresult->length))
                    {
                      yyresult->token = YYUNDEF;
                      yyresult->is_layout = 0;
                      yyresult->is_character_token = 0;
                      yyresult->from_fallback = 0;
                      return yyresult->token;
                    }
        #{pslr_token_actions_enabled? ? "          YYPSLR_TOKEN_ACTION (yytoken, *yyinput, yyresult->length, yylvalp);" : ""}
                  *yyinput += yyresult->length;
                  *yyinput_len -= (size_t)yyresult->length;
                  continue;
                }

        #{pslr_token_actions_enabled? ? "      YYPSLR_TOKEN_ACTION (yytoken, *yyinput, yyresult->length, yylvalp);" : ""}
              return yytoken;
            }
        }
      C_CODE
    end

    # Generate the pure-mode lexer: yylex is emitted by the generator and
    # drives the pseudo-scanner with the current parser state, so no user
    # lexer is involved (%define api.pslr.lexer generated, section 3.1).
    def pslr_generated_lexer_function
      return "" unless pslr_pure_mode?

      params = ["YYSTYPE *yylvalp"]
      params << "YYLTYPE *yyllocp" if @grammar.locations
      params << lex_param unless lex_param.empty?
      unused = []
      unused << "  YY_USE (#{lex_param_name});" unless lex_param.empty?

      location_declarations = location_reset = location_start = location_end = ""
      if @grammar.locations
        location_declarations = <<~C_CODE
          static const char *yypslr_location_cursor = 0;
          static int yypslr_line = 1;
          static int yypslr_column = 1;

          static void
          yypslr_update_location (void)
          {
            while (yypslr_location_cursor != yypslr_input_cursor)
              {
                if (*yypslr_location_cursor++ == '\\n')
                  {
                    yypslr_line++;
                    yypslr_column = 1;
                  }
                else
                  yypslr_column++;
              }
          }
        C_CODE
        location_reset = <<~C_CODE
            yypslr_location_cursor = input;
            yypslr_line = yypslr_column = 1;
        C_CODE
        location_start = <<~C_CODE
            yypslr_update_location ();
            yyllocp->first_line = yypslr_line;
            yyllocp->first_column = yypslr_column;
        C_CODE
        location_end = <<~C_CODE
            yypslr_update_location ();
            yyllocp->last_line = yypslr_line;
            yyllocp->last_column = yypslr_column;
        C_CODE
      end

      scan = if pslr_scanner_enabled?
        <<~C_CODE
            yypslr_scan_result yypslr_result;
            yypslr_token = yypslr_scan_with_layout (yypslr_parser_state,
                                                    &yypslr_input_cursor,
                                                    &yypslr_input_remain,
                                                    yylvalp,
                                                    &yypslr_result#{lex_param.empty? ? "" : ", #{lex_param_name}"});
            yypslr_length = yypslr_result.length;
        C_CODE
      else
        <<~C_CODE
            YY_USE (yylvalp);
            YYPSLR_LAYOUT_CLEAR ();
            yypslr_token = yypslr_input_remain ? YYUNDEF : #{eof_symbol.id.s_value};
            yypslr_length = yypslr_input_remain ? 1 : 0;
        #{pslr_token_actions_enabled? ? "    if (yypslr_token == #{eof_symbol.id.s_value})\n      YYPSLR_TOKEN_ACTION (yypslr_token, yypslr_input_cursor, 0, yylvalp);" : ""}
        C_CODE
      end

      <<~C_CODE

        /* Pure-mode PSLR lexer: generated, owns the input cursor. */
        static const char *yypslr_input_cursor = 0;
        static size_t yypslr_input_remain = 0;
        static int yypslr_parser_state = 0;
        #{location_declarations}

        void
        yypslr_set_input (const char *input, size_t input_len)
        {
          YYPSLR_LAYOUT_CLEAR ();
          yypslr_input_cursor = input;
          yypslr_input_remain = input_len;
          yypslr_parser_state = 0;
        #{location_reset}
        }

        #define YYPSLR_SET_PARSER_STATE(State) (yypslr_parser_state = (State))

        static int
        yylex (#{params.join(", ")})
        {
          int yypslr_token;
          int yypslr_length;
        #{unused.join("\n")}

        #{scan}
        #{location_start}
          if (yypslr_token != YYEMPTY && yypslr_token != #{eof_symbol.id.s_value})
            {
              yypslr_input_cursor += yypslr_length;
              yypslr_input_remain -= (size_t) yypslr_length;
            }
        #{location_end}
          return yypslr_token;
        }
      C_CODE
    end

    # Generate all PSLR C code
    def pslr_tables_and_functions
      return "" unless pslr_scanner_enabled? || pslr_pure_mode?

      parts = [
        "/* PSLR(1) Scanner Tables and Functions */",
        "/* Generated by Lrama PSLR implementation */",
        "",
        scanner_transition_table,
        state_to_accepting_table,
        token_pattern_token_ids_table,
        accepting_tokens_table,
        scanner_accepts_table_code,
        length_precedences_table_code,
        pslr_layout_declarations,
        pseudo_scan_function,
        pslr_token_action_function,
        pslr_layout_scan_function,
        pslr_generated_lexer_function,
      ]

      parts.join("\n")
    end

    private

    def eval_template(file, path)
      tmp = ERB.render(file, context: @context, output: self)
      replace_special_variables(tmp, path)
    end

    def template_file
      File.join(template_dir, @template_name)
    end

    def header_template_file
      File.join(template_dir, "bison/yacc.h")
    end

    def partial_file(file)
      File.join(template_dir, file)
    end

    def template_dir
      File.expand_path('../../template', __dir__)
    end

    def string_array_to_string(ary)
      result = ""
      tmp = " "

      ary.each do |s|
        replaced = s.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
        if (tmp + replaced + " \"\",").length > 75
          result = "#{result}#{tmp}\n"
          tmp = "  \"#{replaced}\","
        else
          tmp = "#{tmp} \"#{replaced}\","
        end
      end

      result + tmp
    end

    def replace_special_variables(str, ofile)
      str.each_line.with_index(1).map do |line, i|
        line.gsub!("[@oline@]", (i + 1).to_s)
        line.gsub!("[@ofile@]", "\"#{ofile}\"")
        line
      end.join
    end
  end
end

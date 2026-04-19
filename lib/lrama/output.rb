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

    # Check if PSLR scanner tables are available.
    def pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa
      !scanner_fsa.nil? && !scanner_fsa.states.empty?
    end

    def pslr_function_declarations
      return "" unless pslr_enabled?

      declarations = [<<~C_CODE]
        int yy_state_accepts_token (int yystate, int yychar);
      C_CODE

      if pslr_scanner_enabled?
        declarations << <<~C_CODE
          int yy_pseudo_scan (int parser_state, const char *input, int *match_length);
        C_CODE

        declarations << <<~C_CODE
          #define YYPSLR_ENABLED 1
          #define YYPSLR_NO_MATCH YYEMPTY

          #ifndef YYPSLR_PSEUDO_SCAN_STATE
          # define YYPSLR_PSEUDO_SCAN_STATE(ParserState, Input, MatchLength) \\
            yy_pseudo_scan ((ParserState), (Input), (MatchLength))
          #endif
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
            # define YYPSLR_PSEUDO_SCAN(Context, Input, MatchLength) \\
              ((Context) != 0 \\
               ? YYPSLR_PSEUDO_SCAN_STATE (YYGETSTATE_CONTEXT (Context), (Input), (MatchLength)) \\
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
      lines.join("\n")
    end

    # Generate token IDs for accepting states as C code
    def accepting_tokens_table
      return "" unless pslr_scanner_enabled?
      scanner_fsa = @context.states.scanner_fsa

      lines = []
      lines << ""
      lines << "/* Accepting state token IDs */"
      lines << "/* For each accepting state, list of (token_id, definition_order) pairs */"
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

        @context.states.states.each_with_index do |parser_state, ps_idx|
          row = []
          pslr_accepting_states.each do |fsa_state|
            token = scanner_accepts[parser_state.id, fsa_state.id]
            if token
              row << token.definition_order
            else
              row << -1
            end
          end

          lines << "  /* parser state #{ps_idx} */ {#{row.join(', ')}}#{ps_idx < num_parser_states - 1 ? ',' : ''}"
        end

        lines << "};"
      end

      lines.join("\n")
    end

    # Generate length_precedences table as C code
    def length_precedences_table_code
      return "" unless pslr_scanner_enabled?
      length_precedences = @context.states.length_precedences
      return "" unless length_precedences

      lines = []
      lines << ""
      lines << "/* length_precedences[token1][token2] -> precedence */"
      lines << "#define YY_LENGTH_PREC_UNDEFINED 0"
      lines << "#define YY_LENGTH_PREC_LEFT 1      /* shorter token wins */"
      lines << "#define YY_LENGTH_PREC_RIGHT 2     /* longer token wins */"
      lines << ""

      num_tokens = pslr_token_pattern_count
      if num_tokens > 0
        lines << "static const int yy_length_precedences[#{num_tokens}][#{num_tokens}] = {"

        @context.states.token_patterns.each_with_index do |t1, i|
          row = @context.states.token_patterns.map do |t2|
            case length_precedences.precedence(t1.name, t2.name)
            when :left then 1
            when :right then 2
            else 0
            end
          end
          lines << "  /* #{t1.name} */ {#{row.join(', ')}}#{i < num_tokens - 1 ? ',' : ''}"
        end

        lines << "};"
      end

      lines.join("\n")
    end

    # Generate pseudo_scan function as C code
    def pseudo_scan_function
      return "" unless pslr_scanner_enabled?

      <<~C_CODE

        /*
         * pseudo_scan: PSLR(1) scanning function
         * Based on Definition 3.2.16 from the PSLR dissertation
         *
         * Input:
         *   parser_state: Current parser state
         *   input: Input buffer pointer
         *   match_length: Output parameter for matched length
         *
         * Returns: Selected parser token ID, or YYEMPTY if no match
         */
        int
        yy_pseudo_scan(int parser_state, const char *input, int *match_length)
        {
          int local_match_length = 0;
          int ss = 0;  /* FSA initial state */
          int ibest = 0;
          int pbest = YY_PSLR_EMPTY_PATTERN;
          int i = 0;

          if (match_length == NULL) {
            match_length = &local_match_length;
          }

          *match_length = 0;

          if (parser_state < 0 || parser_state >= YY_NUM_PARSER_STATES || input == NULL) {
            return YYEMPTY;
          }

          while (input[i] != '\\0') {
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
                /* Check length precedences */
                if (pbest == YY_PSLR_EMPTY_PATTERN ||
                    (i > ibest && yy_length_precedences[pbest][pattern_index] != YY_LENGTH_PREC_LEFT) ||
                    (i == ibest && yy_length_precedences[pattern_index][pbest] == YY_LENGTH_PREC_LEFT)) {
                  pbest = pattern_index;
                  ibest = i;
                }
              }
            }
          }

          *match_length = ibest;
          if (pbest == YY_PSLR_EMPTY_PATTERN) {
            return YYEMPTY;
          }

          return yy_token_pattern_to_token_id[pbest];
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
        lines << "#define YY_CTX_%-8s 0x%02x" % [lc.name, lc.bitmask]
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
      lines << "static const unsigned char yy_lexer_context[] = {"

      table.each_with_index do |ctx, idx|
        ctx_name = LexerContextClassifier.context_name(ctx, lexer_contexts)
        comma = idx < table.size - 1 ? "," : ""
        lines << "  /* state #{idx} */ #{ctx}#{comma} /* #{ctx_name} */"
      end

      lines << "};"
      lines << ""
      lines << "int"
      lines << "yy_lexer_context_is(int yystate, int ctx_mask) {"
      lines << "    if (yystate < 0 || yystate >= #{table.size}) return 0;"
      lines << "    return yy_lexer_context[yystate] & ctx_mask;"
      lines << "}"

      lines.join("\n")
    end

    # Generate all PSLR C code
    def pslr_tables_and_functions
      return "" unless pslr_scanner_enabled?

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
        pseudo_scan_function,
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

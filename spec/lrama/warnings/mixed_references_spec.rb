# frozen_string_literal: true

RSpec.describe Lrama::Warnings::MixedReferences do
  describe "#warn" do
    context "when warnings true" do
      it "warns about mixed positional and named references in a rule" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left] NUM[right]
              {
                $result = $1 + $right;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/mixed_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM NUM` mixes positional and named references; use named references consistently")
      end

      it "does not warn when named references are used consistently" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left] NUM[right]
              {
                $result = $left + $right;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/named_references_only.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "warns once when references are mixed across actions in the same rule" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM
              {
                observe_value($1);
              }
              NUM[right]
              {
                $result = $right;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/mixed_across_actions.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with(/warning: rule `expr: .*` mixes positional and named references; use named references consistently/).once
      end

      it "does not warn when positional references are used consistently" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left] NUM[right]
              {
                consume_pair($1, $2);
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/positional_references_only.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "warns when mixing location and named value references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                assign_location(@1);
                $result = $left;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/location_and_named_value_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM` mixes positional and named references; use named references consistently")
      end

      it "warns when mixing address-of location references and named value references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left] NUM[right]
              {
                build_span(&@1, &@2);
                $result = $left + $right;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/address_of_location_and_named_value_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM NUM` mixes positional and named references; use named references consistently")
      end

      it "warns when mixing index and named value references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                remember_index($:1);
                $result = $left;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/index_and_named_value_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM` mixes positional and named references; use named references consistently")
      end

      it "does not warn when using only special and positional index references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                set_error_index($:$);
                remember_index($:1);
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/special_and_positional_index_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "warns when mixing LHS alias and positional references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                $result = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/lhs_alias_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM` mixes positional and named references; use named references consistently")
      end

      it "does not warn when mixing special LHS and positional references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                $$ = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/special_lhs_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "does not warn when multibyte text appears before special LHS references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                /* あ */
                $$ = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/multibyte_before_special_lhs_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "does not warn when mixing tagged special LHS and positional references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                $<i>$ = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/tagged_special_lhs_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "does not warn when multibyte text appears before tagged special LHS references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                /* あ */
                $<i>$ = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/multibyte_before_tagged_special_lhs_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).not_to have_received(:warn).with(/mixes positional and named references/)
      end

      it "warns when mixing $0 and named symbol references in the same rule" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> LEFT RIGHT tPLUS
          %type <i> expr
          %%
          program: expr
                 ;
          expr: LEFT tPLUS RIGHT
              {
                $0 = $LEFT + $3;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/zero_positional_and_named_symbol_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: LEFT tPLUS RIGHT` mixes positional and named references; use named references consistently")
      end

      it "warns when mixing tagged LHS alias and positional references" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left]
              {
                $<i>result = $1;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/tagged_lhs_alias_and_positional_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, true).warn(grammar, states)

        expect(logger).to have_received(:warn).with("warning: rule `expr: NUM` mixes positional and named references; use named references consistently")
      end
    end

    context "when warnings false" do
      it "does not warn even if references are mixed" do
        source = <<~Y
          %{
          // Prologue
          %}
          %union {
              int i;
          }
          %token <i> NUM
          %type <i> expr
          %%
          program: expr
                 ;
          expr[result]: NUM[left] NUM[right]
              {
                $result = $1 + $right;
              }
              ;
        Y

        grammar = Lrama::Parser.new(source, "warnings/mixed_references.y").parse
        grammar.prepare
        grammar.validate!
        states = Lrama::States.new(grammar, Lrama::Tracer.new(Lrama::Logger.new))
        states.compute
        logger = instance_spy(Lrama::Logger)

        Lrama::Warnings.new(logger, false).warn(grammar, states)

        expect(logger).not_to have_received(:warn)
      end
    end
  end
end

# frozen_string_literal: true

module IELRGrammar
  def self.generate(seed)
    random = Random.new(seed)
    terminals = 5.times.map { |index| "t#{index}" }
    nonterminals = 7.times.map { |index| "n#{index}" }
    lines = ["/* IELR differential generator seed #{seed}. */", "%define lr.type ielr", "%token #{terminals.join(' ')}"]

    terminals.shuffle(random: random).each do |terminal|
      directive = %w[%left %right %nonassoc %precedence].sample(random: random)
      lines << "#{directive} #{terminal}"
    end

    lines << "%%" << "start: n0;"
    nonterminals.each_with_index do |nonterminal, index|
      # shortcut: generated grammars are acyclic; use fixtures to cover recursive grammars.
      symbols = terminals + nonterminals.drop(index + 1)
      alternatives = [terminals.sample(random: random)]
      random.rand(1..2).times do
        rhs = Array.new(random.rand(0..2)) { symbols.sample(random: random) }
        rhs << "%prec #{terminals.sample(random: random)}" if random.rand(4).zero?
        alternatives << rhs.join(' ')
      end
      lines << "#{nonterminal}: #{alternatives.uniq.join(' | ')};"
    end

    lines.join("\n") + "\n"
  end
end

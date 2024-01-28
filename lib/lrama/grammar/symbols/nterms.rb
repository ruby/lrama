module Lrama
  class Grammar
    class Symbols
      class Nterms < Base
        def add(id:, alias_name: nil, tag: nil)
          @symbols << Symbol.new(
            id: id, alias_name: alias_name, number: nil, tag: tag,
            term: false, token_id: nil, nullable: nil,
          )
        end

        def unset_nullable
          @symbols.select {|e| e.nullable.nil? }
        end

        def find_by_id!(id)
          @symbols.find do |s|
            s.id == id
          end || (raise "Symbol not found: #{id}")
        end

        # Fill nterm's tag defined by %type decl
        def fill_type(types)
          types.each do |type|
            nterm = find_by_id!(type.id)
            nterm.tag = type.tag
          end
        end

        # Fill #number and #token_id
        def fill_symbol_number(used_numbers)
          number = INITIAL_NUMBER
          token_id = 0

          @symbols.each do |sym|
            while used_numbers[number] do
              number += 1
            end

            if sym.number.nil?
              sym.number = number
              used_numbers[number] = true
              number += 1
            end

            if sym.token_id.nil?
              sym.token_id = token_id
              token_id += 1
            end
          end
        end
      end
    end
  end
end

RSpec.describe Lrama::State do
  let(:grammar) { <<-FILE }
  %union {
      int val;
  }

  %token a
  %token b
  %token c
  %define lr.type ielr

  %%
  S: a A B a
   | b A B b
  A: a C D E
  B: c
   | // empty
  C: D
  D: a
  E: a
   | // empty
  %%
  FILE


  describe '#internal_dependencies' do

  end
end

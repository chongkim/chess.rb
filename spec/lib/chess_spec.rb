require "chess"

include ChessHelper

describe Fixnum do
  context "#to_sq" do
    it { expect(0.to_sq).to eq :a8 }
    it { expect(1.to_sq).to eq :b8 }
    it { expect(8.to_sq).to eq :a7 }
  end
end

describe Symbol do
  context "#color" do
    it { expect(:-.color).to eq :none }
    it { expect(:R.color).to eq :white }
    it { expect(:r.color).to eq :black }
  end
end

describe ChessHelper do
  context "coords" do
    it { expect(a8).to eq 0 }
    it { expect(b8).to eq 1 }
    it { expect(a7).to eq 8 }
  end
  context "white" do
    it { expect(white(:white,1,0)).to eq 1 }
    it { expect(white(:black,1,0)).to eq 0 }
    it { expect(white(:R,1,0)).to eq 1 }
    it { expect(white(:r,1,0)).to eq 0 }
    it { expect(white(:-,1,0)).to eq nil }
  end
  context "xydiff" do
    it { expect(xydiff(a8,b3)).to eq [1,5] }
  end
end

describe Position do
  context ".new" do
    its(:e4) { should == :- }
    its(:e2) { should == :P }
    its(:d1) { should == :Q }
    its(:d8) { should == :q }
    its(:turn) { should == :white }
    its(:castling) { should == [:K, :Q, :k, :q] }
    its(:ep) { should == nil }
    its(:halfmove) { should == 0 }
    its(:fullmove) { should == 1 }
  end
  context ".[]" do
    subject { Position[R: e4, :turn => :black] }
    its(:e4) { should == :R }
    its(:e2) { should == :- }
    its(:turn) { should == :black }
  end
  context "#==" do
    it { expect(Position[R: e4]).to eq Position[R: e4] }
  end
  context "#path_clear" do
    it { expect(subject.path_clear(e2,e7)).to eq true }
    it { expect(subject.path_clear(e2,b2)).to eq false }
  end
  context "#move_piece" do
    it { expect(Position[R: e4].move_piece(e4,e2)).to eq Position[R: e2] }
    it { expect(Position[R: e4].move_piece(e4,d3)).to eq nil }
    it { expect(Position[R: e4, P: e3].move_piece(e4,e2)).to eq nil } 
    it { expect(Position[R: e4, P: e2].move_piece(e4,e2)).to eq nil }
    it { expect(Position[R: e4, p: e2].move_piece(e4,e2)).to eq Position[R: e2] }
    it { expect(Position[N: e4].move_piece(e4,c3)).to eq Position[N: c3] }
    it { expect(Position[N: e4].move_piece(e4,e5)).to eq nil }
    it { expect(Position[N: e4, P: [d3,d4,d5]].move_piece(e4,c3)).to eq Position[N: c3, P: [d3,d4,d5]] }
    it { expect(Position[b: e4].move_piece(e4,f5)).to eq Position[b: f5] }
    it { expect(Position[b: e4].move_piece(e4,e5)).to eq nil }
    it { expect(Position[K: e4].move_piece(e4,e5)).to eq Position[K: e5] }
    it { expect(Position[K: e4].move_piece(e4,e6)).to eq nil }
    it { expect(Position[P: e2].move_piece(e2,e3)).to eq Position[P: e3] }
    it { expect(Position[P: e2, r: e3].move_piece(e2,e3)).to eq nil }
    it { expect(Position[P: e2].move_piece(e2,e4)).to eq Position[P: e4, :ep => e3] }
    it { expect(Position[P: e2, r:e4].move_piece(e2,e4)).to eq nil }
    it { expect(Position[P: e2].move_piece(e2,d6)).to eq nil }
    it { expect(Position[P: e2].move_piece(e2,e1)).to eq nil }
    it { expect(Position[P: e2].move_piece(e2,d3)).to eq nil }
    it { expect(Position[P: e2, r:d3].move_piece(e2,d3)).to eq Position[P: d3] }
    it { expect(Position[P: e5, p:f5, :ep => f6].move_piece(e5,f6)).to eq Position[P: f6] }
  end
end

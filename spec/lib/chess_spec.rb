require "chess"

include ChessHelper

describe ChessHelper do
  context "to_idx" do
    it { expect(to_idx(0)).to eq 0 }
    it { expect(to_idx(:a8)).to eq 0 }
    it { expect(to_idx(:h8)).to eq 7 }
    it { expect(to_idx(:h1)).to eq 63 }
  end
  context "color" do
    it { expect(color("P")).to eq :white }
    it { expect(color("p")).to eq :black }
    it { expect(color("-")).to be_nil }
  end
  context "xydiff" do
    it { expect(xydiff(0,1)).to eq [1,0] }
    it { expect(xydiff(0,8)).to eq [0,1] }
  end
  context "to_sq" do
    it { expect(to_sq(:e4)).to eq :e4 }
    it { expect(to_sq("e4")).to eq :e4 }
    it { expect(to_sq(to_idx(:f4))).to eq :f4 }
  end
end

describe Position do
  its(:board) { should == %w(-)*64 }
  its(:turn) { should == :white }
  its(:ep) { should be_nil }
  its(:castling) { should == %w(K Q k q) }
  its(:halfmove) { should == 0 }
  its(:fullmove) { should == 1 }
  context ".new(args)" do
    it { expect(Position.new(:black).turn).to eq :black }
    it { expect(Position.new(:turn => :black).turn).to eq :black }
  end
  context ".[]" do
    subject { Position["Re4 .. Be1 e2", :black] }
    it { expect(subject[:e4]).to eq "R" }
    it { expect(subject[:e1]).to eq "b" }
    it { expect(subject[:e2]).to eq "p" }
    its(:turn) { should == :black }
  end
  context "path_clear" do
    it { expect(Position["Re4"].path_clear(to_idx(:e4), to_idx(:e2))).to be_true  }
    it { expect(Position["Re4 e3"].path_clear(to_idx(:e4), to_idx(:e2))).to be_false  }
    it { expect(Position["Re4 e2"].path_clear(to_idx(:e4), to_idx(:e2))).to be_true  }
  end
  context "#find" do
    it { expect(Position["Re4"].find("R", :e2)).to eq [:e4] }
    it { expect(Position["Re4 e2"].find("R", :e2)).to eq [] }
    it { expect(Position["Re4 e3"].find("R", :e2)).to eq [] }
    it { expect(Position["Re4 Re1"].find("R", :e2)).to eq [:e4, :e1] }
    it { expect(Position["Re4 Rd1"].find("R", :e2)).to eq [:e4] }
    it { expect(Position["Re4 e2"].find("R", :e2)).to eq [] }
    it { expect(Position["Re4 .. e2"].find("R", :e2)).to eq [:e4] }
    it { expect(Position["Ne4"].find("N", :c3)).to eq [:e4] }
    it { expect(Position["Ne4"].find("N", :e2)).to eq [] }
    it { expect(Position["Ne4 d3 d4 d5"].find("N", :c3)).to eq [:e4] }
    it { expect(Position[".. Be4", :black].find("b", :f3)).to eq [:e4] }
    it { expect(Position[".. Be4", :black].find("b", :f4)).to eq [] }
    it { expect(Position["Qe4"].find("Q", :e2)).to eq [:e4] }
    it { expect(Position["Qe4"].find("Q", :a8)).to eq [:e4] }
    it { expect(Position["Qe4"].find("Q", :c3)).to eq [] }
    it { expect(Position["Ke4"].find("K", :e3)).to eq [:e4] }
    it { expect(Position["Ke3"].find("K", :e5)).to eq [] }
    it { expect(Position["e2"].find("P", :e3)).to eq [:e2] }
    it { expect(Position["e2"].find("P", :e4)).to eq [:e2] }
    it { expect(Position["e2"].find("P", :e5)).to eq [] }
    it { expect(Position["e2 .. e3"].find("P", :e3)).to eq [] }
    it { expect(Position["e2 .. f3"].find("P", :f3)).to eq [:e2] }
    it { expect(Position["e3"].find("P", :e5)).to eq [] }
    it { expect(Position["e5 .. f5", :ep => :f6].find("P", :f6)).to eq [:e5] }
    it { expect(Position["e4 .. g6"].find("P", :g6)).to eq [] }
  end
end

require "chess"
require "debugger"

include ChessHelper

describe ChessHelper do
  context "coord" do
    it { expect(a8).to eq 21 }
    it { expect(h8).to eq 28 }
    it { expect(a1).to eq 91 }
    it { expect(h1).to eq 98 }
  end
end

describe String do
  context "to_idx" do
    it { expect("a8".to_idx).to eq 21 }
    it { expect("h8".to_idx).to eq 28 }
    it { expect("a1".to_idx).to eq 91 }
    it { expect("h1".to_idx).to eq 98 }
  end
end
describe Fixnum do
  context "to_sq" do
    it { expect(21.to_sq).to eq "a8" }
    it { expect(28.to_sq).to eq "h8" }
    it { expect(91.to_sq).to eq "a1" }
    it { expect(98.to_sq).to eq "h1" }
  end
end

describe Position do
  context ".new" do
    it { expect(subject.board[e4]).to eq nil }
    it { expect(subject.board[e2]).to eq "P" }
    it { expect(subject.board[d1]).to eq "Q" }
    it { expect(subject.board[d8]).to eq "q" }
    its(:turn) { should == :white }
    its(:castling) { should == "KQkq" }
    its(:ep) { should == nil }
    its(:halfmove) { should == 0 }
    its(:fullmove) { should == 1 }
    its(:king) { should == { white: e1, black: e8 } }
  end
  context "#move" do
    context "e4" do
      subject { Position.new.move("e4") }
      it { expect(subject.board[e4]).to eq "P" }
      it { expect(subject.board[e2]).to eq nil }
      its(:turn) { should == :black }
      its(:castling) { should == "KQkq" }
      its(:ep) { should == e3 }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 1 }
    end
    context "e4 e5" do
      subject { Position.new.move("e4").move("e5") }
      it { expect(subject.board[e5]).to eq "p" }
      it { expect(subject.board[e7]).to eq nil }
      its(:turn) { should == :white }
      its(:castling) { should == "KQkq" }
      its(:ep) { should == e6 }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 2 }
    end
    context "e4 e5 Nf3" do
      subject { Position.new.move("e4").move("e5").move("Nf3") }
      it { expect(subject.board[f3]).to eq "N" }
      it { expect(subject.board[g1]).to eq nil }
      its(:turn) { should == :black }
      its(:castling) { should == "KQkq" }
      its(:ep) { should == nil }
      its(:halfmove) { should == 1 }
      its(:fullmove) { should == 2 }
    end
    context "e4 e5 Nf3 Nf6" do
      subject { Position.new.move("e4").move("e5").move("Nf3").move("Nf6") }
      it { expect(subject.board[f6]).to eq "n" }
      it { expect(subject.board[g8]).to eq nil }
      its(:turn) { should == :white }
      its(:castling) { should == "KQkq" }
      its(:ep) { should == nil }
      its(:halfmove) { should == 2 }
      its(:fullmove) { should == 3 }
    end
    context "e4 e5 Nf3 Nf6 Nxe5" do
      subject { Position.new.move("e4").move("e5").move("Nf3").move("Nf6").move("Nxe5") }
      it { expect(subject.board[e5]).to eq "N" }
      it { expect(subject.board[f3]).to eq nil }
      its(:turn) { should == :black }
      its(:castling) { should == "KQkq" }
      its(:ep) { should == nil }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 3 }
    end
    context "read moves from pgn" do
      it {
        File.open("games/Morphy.pgn", "r") do |f|
          position = Position.new
          game = 1
          while line = f.gets
            next if line.start_with?("[")
            line.gsub(/\b\d+\./,"").split.each do |str|
              case str
              when %r"^1-0$|^0-1$|^1/2-1/2$|^\*$" then
                position = Position.new
                game += 1
              else
                position.move(str)
                # puts "", "Game #{game}", position, str
              end
            end
          end
        end
      }
    end
  end
end

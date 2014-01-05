require "chess"

include ChessHelper

def xcontext(*args)
end
 
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
    it { expect(subject[e4]).to eq :- }
    it { expect(subject[e2]).to eq :P }
    it { expect(subject[d1]).to eq :Q }
    it { expect(subject[d8]).to eq :q }
    its(:turn) { should == :white }
    its(:castling) { should == [:K, :Q, :k, :q] }
    its(:ep) { should == nil }
    its(:halfmove) { should == 0 }
    its(:fullmove) { should == 1 }
  end
  context ".[]" do
    subject { Position[R: e4, :turn => :black] }
    it { expect(subject[e4]).to eq :R }
    it { expect(subject[e2]).to eq :- }
    its(:turn) { should == :black }
  end
  context "#==" do
    it { expect(Position[R: e4]).to eq Position[R: e4] }
  end
  context "#path_clear" do
    it { expect(subject.path_clear(e2,e7)).to eq true }
    it { expect(subject.path_clear(e2,b2)).to eq false }
  end
  context "#dup" do
    it {
      position = subject.dup
      subject[e4] = :R
      expect(position[e4]).to eq :-
    }
    it {
      position = subject.dup
      subject.move_piece(e2,e4)
      expect(position[e4]).to eq :-
    }
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
    it { expect(Position[K: e1, R: h1, :castling => [:Q, :k, :q]].move_piece(e1,g1)).to eq nil }
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

  context "#move" do
    context "e4" do
      subject { Position.new.move("e4") }
      it { expect(subject[e4]).to eq :P }
      it { expect(subject[e2]).to eq :- }
      its(:turn) { should == :black }
      its(:castling) { should == [:K, :Q, :k, :q] }
      its(:ep) { should == e3 }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 1 }
    end
    context "e4 e5" do
      subject { Position.new.move("e4").move("e5") }
      it { expect(subject[e5]).to eq :p }
      it { expect(subject[e7]).to eq :- }
      its(:turn) { should == :white }
      its(:castling) { should == [:K, :Q, :k, :q] }
      its(:ep) { should == e6 }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 2 }
    end
    context "e4 e5 Nf3" do
      subject { Position.new.move("e4").move("e5").move("Nf3") }
      it { expect(subject[f3]).to eq :N }
      it { expect(subject[g1]).to eq :- }
      its(:turn) { should == :black }
      its(:castling) { should == [:K, :Q, :k, :q] }
      its(:ep) { should == nil }
      its(:halfmove) { should == 1 }
      its(:fullmove) { should == 2 }
    end
    context "e4 e5 Nf3 Nf6" do
      subject { Position.new.move("e4").move("e5").move("Nf3").move("Nf6") }
      it { expect(subject[f6]).to eq :n }
      it { expect(subject[g8]).to eq :- }
      its(:turn) { should == :white }
      its(:castling) { should == [:K, :Q, :k, :q] }
      its(:ep) { should == nil }
      its(:halfmove) { should == 2 }
      its(:fullmove) { should == 3 }
    end
    context "e4 e5 Nf3 Nf6 Nxe5" do
      subject { Position.new.move("e4").move("e5").move("Nf3").move("Nf6").move("Nxe5") }
      it { expect(subject[e5]).to eq :N }
      it { expect(subject[f3]).to eq :- }
      its(:turn) { should == :black }
      its(:castling) { should == [:K, :Q, :k, :q] }
      its(:ep) { should == nil }
      its(:halfmove) { should == 0 }
      its(:fullmove) { should == 3 }
    end
  end
  context "#possible_moves" do
    context "for a sq" do
      subject { Position.new.possible_moves(g1) }
      it { expect(subject).to eq [[g1, f3], [g1, h3]] }
    end
    context "all possible moves" do
      subject { Position.new.possible_moves }
      it { expect(subject).to include [e2,e4] }
    end
  end
  context "#checkmate?" do
    it { expect(Position[K: e1, k: e3].checkmate?).to eq false }
    it { expect(Position[K: e1, k: e3, q: e2].checkmate?).to eq true }
    it { expect(Position[k: e1, K: e3, Q: e2, :turn => :black].checkmate?).to eq true }
  end
  context "#checkmate?" do
    it { expect(Position[K: e1, k: e3].stalemate?).to eq false }
    it { expect(Position[K: e1, k: e3, p: e2].stalemate?).to eq true }
    it { expect(Position[k: e8, K: e6, P: e7, :turn => :black].stalemate?).to eq true }
  end
  context "#minimax" do
    it { expect(Position[K: e1, k: e3, q: e2].minimax).to eq (-100) }
    it { expect(Position[k: e1, K: e3, Q: e2, :turn => :black].minimax).to eq 100 }
    it { expect(Position[K: e1, k: e3, p: e2].minimax).to eq 0 }
    it { expect(Position[K: e1, k: e3, p: e2, :halfmove => 100].minimax).to eq 0 }
    it { expect(Position[K: e1, k: e3, q: d3, :turn => :black].minimax).to eq (-99) }
    it { expect(Position[k: e1, K: e3, Q: d3, :turn => :white].minimax).to eq 99 }
  end
  context "#best_move" do
    it { expect(Position[K: e1, k: e3, q: d3, :turn => :black].best_move).to eq [d3, e2] }
    it { expect(Position[k: e1, K: e3, Q: d3, :turn => :white].best_move).to eq [d3, e2] }
  end
  xcontext "reads from pgn file" do
    it {
      File.open("games/Morphy.pgn", "r") do |f|
        position = Position.new
        game = 1
        while line = f.gets
          next if line.start_with?("[")
          line.gsub(/\b\d+\./,"").split.each do |m|
            case m
            when %r"^1-0$|^0-1$|^1/2-1/2$|\*"
              position = Position.new
              game += 1
            else
              position.move(m)
              # puts "", "Game #{game}", position, m
            end
          end
        end
      end
    }
  end
end

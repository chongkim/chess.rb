require "chess"
require "debugger"

include ChessHelper

describe ChessHelper do
  context "coordinates" do
    it { expect(a8).to eq 0 }
    it { expect(b8).to eq 1 }
    it { expect(a7).to eq 8 }
  end
  context "white" do
    it { expect(white(:white,1,0)).to eq 1 }
    it { expect(white(:black,1,0)).to eq 0 }
    it { expect(white(nil,1,0)).to be_nil }
    it { expect(white("R",1,0)).to eq 1 }
    it { expect(white("r",1,0)).to eq 0 }
    it { expect(white("-",1,0)).to be_nil }
  end
  context "to_sq" do
    it { expect(to_sq(0)).to eq :a8 }
    it { expect(to_sq(1)).to eq :b8 }
    it { expect(to_sq(8)).to eq :a7 }
  end
  context "xydiff" do
    it { expect(xydiff(e1, g2)).to eq [2, -1] }
  end
  context "color" do
    it { expect(color("R")).to eq :white }
    it { expect(color("r")).to eq :black }
    it { expect(color("-")).to be_nil }
  end
  context "to_col" do
    it { expect(to_col("a")).to eq 0 }
    it { expect(to_col("b")).to eq 1 }
  end
  context "to_row" do
    it { expect(to_row("1")).to eq 7 }
    it { expect(to_row("8")).to eq 0 }
  end
end

describe Position do
  its(:board) { should == %w(r n b q k b n r
                             p p p p p p p p
                             - - - - - - - -
                             - - - - - - - -
                             - - - - - - - -
                             - - - - - - - -
                             P P P P P P P P
                             R N B Q K B N R) }
  its(:turn) { should == :white }
  its(:castling) { should == %w(K Q k q) }
  its(:ep) { should be_nil }
  its(:halfmove) { should == 0 }
  its(:fullmove) { should == 1 }
  context ".new(opts)" do
    subject { Position.new(:turn => :black) }
    its(:turn) { should == :black }
  end
  context ".[]" do
    it { expect(Position["Re4"].board[e4]).to eq "R" }
    it { expect(Position["Re4", :turn => :black].turn).to eq :black }
  end
  context "path_clear" do
    it { expect(Position["Re4"].path_clear(e4, e2)).to be_true }
    it { expect(Position["Re4 Re2"].path_clear(e4, e2)).to be_true }
    it { expect(Position["Re4 e3"].path_clear(e4, e2)).to be_false }
    it { expect(Position["Ne4 d3 d4 d5"].path_clear(e4, c3)).to be_true }
  end
  context "in_check?" do
    it { expect(Position["Ke4 .. Re8"].in_check?).to be_true }
    it { expect(Position["Ke4 .. Nc3"].in_check?).to be_true }
    it { expect(Position["Re8 .. Ke4", :turn => :black].in_check?).to be_true }
    it { expect(Position["Nc3 .. Ke4", :turn => :black].in_check?).to be_true }
    it { expect(Position.new.in_check?).to be_false }
  end
  context "#move_piece" do
    it { expect(Position["Ke1"].move_piece(e1,e1)).to be_nil }
    it { expect(Position["Ke1 Rh1"].move_piece(e1, g1)).to eq Position["Kg1 Rf1", :castling => %w(k q)] }
    it { expect(Position["Ke1 Ra1"].move_piece(e1, c1)).to eq Position["Kc1 Rd1", :castling => %w(k q)] }
    it { expect(Position["Ke1 Rh1"].move_piece(e1, e2)).to eq Position["Ke2 Rh1", :castling => %w(k q)] }
    it { expect(Position["Ke1 Rh1 Ra1"].move_piece(h1, h2)).to eq Position["Ke1 Rh2 Ra1", :castling => %w(Q k q)] }
    it { expect(Position["Ke1 Rh1 Ra1"].move_piece(a1, a2)).to eq Position["Ke1 Rh1 Ra2", :castling => %w(K k q)] }
    it { expect(Position["e5 .. f5", :ep => f6].move_piece(e5, f6)).to eq Position["f6"] }
    it { expect(Position["Re4"].move_piece(e4, e2)).to eq Position["Re2"] }
    it { expect(Position["Re4"].move_piece(e4, d3)).to be_nil }
    it { expect(Position["Ne4"].move_piece(e4, c3)).to eq Position["Nc3"] }
    it { expect(Position["Ne4"].move_piece(e4, c2)).to be_nil }
    it { expect(Position[".. Be4"].move_piece(e4, f5)).to eq Position[".. Bf5"] }
    it { expect(Position[".. Be4"].move_piece(e4, e2)).to be_nil }
    it { expect(Position["Qe4"].move_piece(e4, e2)).to eq Position["Qe2"] }
    it { expect(Position["Qe4"].move_piece(e4, d2)).to be_nil }
    it { expect(Position["Ke4"].move_piece(e4, e3)).to eq Position["Ke3", :castling => %w(k q)] }
    it { expect(Position["Ke4"].move_piece(e4, e2)).to be_nil }
    it { expect(Position["e2"].move_piece(e2, e3)).to eq Position["e3"] }
    it { expect(Position["e2"].move_piece(e2, e4)).to eq Position["e4", :ep => e3] }
    it { expect(Position["e2"].move_piece(e2, c3)).to be_nil }
    it { expect(Position["e4"].move_piece(e4, e3)).to be_nil }
    it { expect(Position["e2 .. e3"].move_piece(e2, e3)).to be_nil }
    it { expect(Position["e2 .. e3"].move_piece(e2, e4)).to be_nil }
    it { expect(Position["e2 .. e4"].move_piece(e2, e4)).to be_nil }
    it { expect(Position["e2 .. d3"].move_piece(e2, d3)).to eq Position["d3"] }
    it { expect(Position["Re4 Be3"].move_piece(e4, e3)).to be_nil  }
    it { expect(Position["Ke4 .. Rf8"].move_piece(e4, f4)).to be_nil }
    it { expect(Position["Kf4 a2 .. Rf8"].move_piece(a2, a3)).to be_nil }
  end
  context "#dup" do
    subject { Position.new }
    let(:position) { subject.dup }
    before(:each) { position.board[e4] = "R" }
    it { expect(subject.board[e4]).to eq "-" }
  end
  context "#move" do
    context "1. e4" do
      subject { Position.new.move("e4") }
      it { expect(subject).to eq Position.new(:board => %w(r n b q k b n r
                                                           p p p p p p p p
                                                           - - - - - - - -
                                                           - - - - - - - -
                                                           - - - - P - - -
                                                           - - - - - - - -
                                                           P P P P - P P P
                                                           R N B Q K B N R),
      :turn => :black, :ep => e3, :castling => %w(K Q k q), :halfmove => 0, :fullmove => 1) }
    end
    context "1. e4 e5" do
      subject { Position.new.
                move("e4").move("e5") }
      it { expect(subject).to eq Position.new(:board => %w(r n b q k b n r
                                                           p p p p - p p p
                                                           - - - - - - - -
                                                           - - - - p - - -
                                                           - - - - P - - -
                                                           - - - - - - - -
                                                           P P P P - P P P
                                                           R N B Q K B N R),
      :turn => :white, :ep => e6, :castling => %w(K Q k q), :halfmove => 0, :fullmove => 2) }
    end
    context "1. e4 e5 2. Nf3" do
      subject { Position.new.
                move("e4").move("e5").
                move("Nf3") }
      it { expect(subject).to eq Position.new(:board => %w(r n b q k b n r
                                                           p p p p - p p p
                                                           - - - - - - - -
                                                           - - - - p - - -
                                                           - - - - P - - -
                                                           - - - - - N - -
                                                           P P P P - P P P
                                                           R N B Q K B - R),
      :turn => :black, :ep => nil, :castling => %w(K Q k q), :halfmove => 1, :fullmove => 2) }
    end
    context "1. e4 e5 2. Nf3 Nc6" do
      subject { Position.new.
                move("e4").move("e5").
                move("Nf3").move("Nc6") }
      it { expect(subject).to eq Position.new(:board => %w(r - b q k b n r
                                                           p p p p - p p p
                                                           - - n - - - - -
                                                           - - - - p - - -
                                                           - - - - P - - -
                                                           - - - - - N - -
                                                           P P P P - P P P
                                                           R N B Q K B - R),
      :turn => :white, :ep => nil, :castling => %w(K Q k q), :halfmove => 2, :fullmove => 3) }
    end
    context "legal moves from pgn file" do
      it {
        position = Position.new
        game_number = 1
        File.open("games/Morphy.pgn", "r") do |f|
          while line = f.gets
            case line
            when /^\[/ then next
            when %r"1-0|0-1|1/2-1/2" then
              game_number += 1
              position = Position.new
              next
            else
              line.gsub(/\b\d+\./,"").split.each do |m|
                expect{ position = position.move(m) }.not_to raise_error
                puts
                puts "Game #{game_number}"
                puts position
                puts m
              end
            end
          end
        end
      }
    end
  end
end

require "debugger"
class Fixnum
  def to_sq
    (('a'.ord + self%8).chr + ('8'.ord - self/8).chr).to_sym
  end
end

module ChessHelper
  INDICES = [*0..63]
  INDICES.each { |idx| define_method(idx.to_sq) { idx } }
  def white(p,w,b)
    case p
    when :white, :R, :N, :B, :Q, :K, :P then w
    when :black, :r, :n, :b, :q, :k, :p then b
    end
  end
  def xydiff(from, to)
    [to%8 - from%8, to/8 - from/8]
  end
end

class Symbol
  def valid_move?(from, to)
    dx, dy = xydiff(from, to)
    case self
    when :R, :r then dx == 0 || dy == 0
    when :N, :n then [dx.abs, dy.abs].sort == [1,2]
    when :B, :b then dx.abs == dy.abs
    when :K, :k then [dx.abs, dy.abs].max <= 1
    when :P, :p then (dx == 0     && dy == white(self,-1,1) ||
                      dx == 0     && dy == white(self,-2,2) && from/8 == white(self,6,1) ||
                      dx.abs == 1 && dy == white(self,-1,1)
                     )

    end
  end
  def color
    @color ||= case self
               when :R, :N, :B, :Q, :K, :P then :white
               when :r, :n, :b, :q, :k, :p then :black
               else :none
               end
  end
  def other_color
    color == :white ? :black : color == :black ? :white : :none
  end
  def pawn?
    self == :P || self == :p
  end
end

class Position
  include ChessHelper
  attr_accessor :turn, :castling, :ep, :halfmove, :fullmove
  def initialize(opts={})
    if opts.any? { |k,v| k.size == 1 }
      @board = [:-]*64
      @pieces = Hash[%w(r n b q k p R N B Q K P).map { |c| [c.to_sym, Set[]] }]
      @pieces[:-] = Set[*0..63]
      opts.each do |p,v|
        next if p.size != 1
        v = [v] unless Array === v
        v.each do |idx|
          self[idx] = p
        end
      end
    else
      @pieces = {}
      @board = %w(r n b q k b n r
                  p p p p p p p p
                  - - - - - - - -
                  - - - - - - - -
                  - - - - - - - -
                  - - - - - - - -
                  P P P P P P P P
                  R N B Q K B N R).map(&:to_sym).each.with_index do |p,idx|
                    @pieces[p] ||= Set[]
                    @pieces[p].add(idx)
                  end
    end
    @turn = opts[:turn] || :white
    @castling = opts[:castling] || [:K, :Q, :k, :q]
    @ep = opts[:ep]
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
  end
  INDICES.each { |idx| define_method(idx.to_sq) { @board[idx] } }
  def self.[](opts)
    Position.new(opts)
  end
  def []=(idx,p)
    @pieces[@board[idx]] ||= Set[]
    @pieces[@board[idx]].delete(idx)
    @pieces[p] ||= Set[]
    @pieces[p].add(idx)
    @board[idx] = p
  end
  def inspect
    b = @board.each_slice(8).map { |row| row.join.gsub(/-+/) { |s| s.size } }.join("/")
    t = white(turn,:w,:b)
    c = castling.empty? ? :- : castling.join
    e = ep || :-
    "#{b} #{t} #{c} #{e} #{halfmove} #{fullmove}"
  end
  def _board; @board; end
  def _pieces; @pieces; end
  def ==(other)
    (self.class == other.class &&
     @board == other._board &&
     @pieces == other._pieces &&
     @turn == other.turn &&
     @castling == other.castling &&
     @ep == other.ep &&
     @halfmove == other.halfmove &&
     @fullmove == other.fullmove)
  end
  def [](idx)
    @board[idx]
  end
  def path_clear(from, to)
    dx, dy = xydiff(from, to)
    return true if !(dx == 0 || dy == 0 || dx.abs == dy.abs)
    d = (dx <=> 0) + (dy <=> 0)*8
    (from+d).step(to-d,d).all? { |idx| @board[idx] == :- }
  end
  def move_piece(from, to)
    dx, dy = xydiff(from, to)
    piece = self[from]
    if piece.valid_move?(from, to) && self[to].color != piece.color && path_clear(from, to) then
      if !piece.pawn? || (dx == 0 && @board[to] == :- ||
                          dx.abs == 1 && @board[to].color == piece.other_color ||
                          to == ep)
        self[ep + white(piece,8,-8)] = :- if piece.pawn? && to == ep
        @ep = piece.pawn? && dx == 0 && dy.abs == 2 ? to + white(piece,8,-8) : nil
        self[to] = piece
        self[from] = :-
        self
      end
    end
  end
end

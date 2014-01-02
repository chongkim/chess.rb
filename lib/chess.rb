require "debugger"
class Fixnum
  def to_sq
    (('a'.ord + self%8).chr + ('8'.ord - self/8).chr).to_sym
  end
end
class String
  def to_idx
    self[0].ord - 'a'.ord + ('8'.ord - self[1].ord)*8
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
  def valid_move(from, to)
    dx, dy = xydiff(from, to)
    case self
    when :R, :r then dx == 0 || dy == 0
    when :N, :n then [dx.abs, dy.abs].sort == [1,2]
    when :B, :b then dx.abs == dy.abs
    when :Q, :q then dx.abs == dy.abs || dx == 0 || dy == 0
    when :K, :k then ([dx.abs, dy.abs].max <= 1 ||
                      from == white(self,e1,e8) && (to == white(self,g1,g8) || to == white(self,c1,c8)))
    when :P, :p then dx == 0 && (dy == white(self,-1,1) || dy == white(self,-2,2) && from/8 == white(self,6,1))
    end
  end
  def valid_capture(from, to)
    dx, dy = xydiff(from, to)
    case self
    when :P, :p then dx.abs == 1 && dy == white(self,-1,1)
    when :K, :k then [dx.abs, dy.abs].max <= 1
    else valid_move(from, to)
    end
  end
  def color
    @color ||= case self
               when :R, :N, :B, :Q, :K, :P then :white
               when :r, :n, :b, :q, :k, :p then :black
               else :none
               end
  end
  def pawn?
    self == :P || self == :p
  end
  def king?
    self == :K || self == :k
  end
end

class IllegalMove < Exception
  def initialize(str,position)
    super("#{str}\n#{position}")
  end
end
class AmbiguousMove < Exception
  def initialize(str,position,list)
    super("#{str}\n#{position} #{list.map(&:to_sq).inspect}")
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
  def initialize_copy(other)
    @board = other._board.dup
    @pieces = other._pieces.dup
    @turn = other.turn
    @castling = other.castling.dup
    @ep = other.ep
    @halfmove = other.halfmove
    @fullmove = other.fullmove
  end
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
  def move_piece(from, to, act=true)
    piece = self[from]
    target = self[to]
    return nil if piece.color == target.color
    is_ep_capture = piece.pawn? && to == ep
    is_capture = target != :- || is_ep_capture
    if (!is_capture && piece.valid_move(from, to) ||
        is_capture && piece.valid_capture(from, to)) && path_clear(from, to) then
      @ep = piece.pawn? && (to - from).abs == 16 ? (to+from)/2 : nil if act
      if is_ep_capture then
        self[to%8 + from/8*8] = :- if act
      end
      self[to] = piece if act
      self[from] = :- if act
      if piece.king? && (to - from).abs == 2 then
        f,t = from < to ? [white(turn,h1,h8), white(turn,f1,f8)] : [white(turn,a1,a8), white(turn,d1,d8)]
        self[t] = self[f] if act
        self[f] = :- if act
      end
      self
    end
  end
  def to_s
    b = @board.map { |p| {R:'♖',N:'♘',B:'♗',Q:'♕',K:'♔',P:'♙',r:'♜',n:'♞',b:'♝',q:'♛',k:'♚',p:'♟'}[p] || p
    }.each_slice(8).map { |row| row.join(" ") }.join("\n")
    c = castling.empty? ? :- : castling.join
    e = ep.nil? ? :- : ep.to_sq
    "#{b} #{turn} #{c} #{e} #{halfmove} #{fullmove} #{@pieces[:n].map(&:to_sq).inspect}"
  end
  def attacked(to, color)
    opponents = [:R, :N, :B, :Q, :K, :P]
    opponents = opponents.map(&:downcase) if color == :black
    opponents.any? { |opponent|
      @pieces[opponent].any? { |from| opponent.valid_capture(from, to) && path_clear(from, to) }
    }
  end
  def move(str)
    list = []
    promote = nil
    if m = str.match(/^(?<piece>[RNBQK])? (?<col>[a-h])?(?<row>[1-8])? x? (?<sq>[a-h][1-8]) (=(?<promote>[RNBQ]))? \+?$/x)
      to = m[:sq].to_idx
      piece = (m[:piece] || "P").to_sym
      piece = piece.downcase if turn == :black
      list = @pieces[piece].to_a
      list.select! { |from| from%8 == m[:col].ord - 'a'.ord } if m[:col]
      list.select! { |from| from/8 == '8'.ord - m[:row].ord } if m[:row]
      list.select! { |from| move_piece(from, to, false) }
      list.select! { |from|
        king_list = @pieces[white(turn,:K,:k)].to_a
        if !king_list.empty? then
          king_idx = piece.king? ? to : king_list[0]
          tmp = self.dup
          tmp.move_piece(from, to)
          !tmp.attacked(king_idx,white(turn,:black,:white))
        else
          false
        end
      }
      promote = m[:promote].send(white(turn,:upcase,:downcase)).to_sym if m[:promote]
    elsif str =~ /^O-O(-O)?$/
      piece = white(turn, :K, :k)
      list = [white(turn, e1, e8)]
      to = str == "O-O" ?  white(turn, g1, g8) : white(turn, c1, c8)
    end
    raise IllegalMove.new(str, self) if list.empty?
    raise AmbiguousMove.new(str, self, list) if 1 < list.size
    from = list[0]
    if piece.pawn? || self[to] != :- then
      @halfmove = 0
    else
      @halfmove += 1
    end
    move_piece(from, to)
    self[to] = promote if promote
    @turn = white(turn, :black, :white)
    @fullmove += 1 if turn == :white
    self
  end
end

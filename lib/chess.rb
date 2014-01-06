require "debugger"

module ChessHelper
  ('a'..'h').each.with_index do |col,i|
    (1..8).each.with_index do |row,j|
      define_method("#{col}#{row}") { i + 1 + (8 - j + 1)*10 }
    end
  end
end

class String
  def to_idx
    self[0].ord - 'a'.ord + 1 + ('8'.ord - self[1].ord + 2)*10
  end
end
class Fixnum
  def to_sq
    (self%10 + 'a'.ord - 1).chr + ('8'.ord - self/10 + 2).chr
  end
end

class IllegalMove < Exception
  def initialize(str, position, list)
    super("#{str}\n#{position}" + (list.empty? ? "" : list.map { |from| from.to_sq }.inspect))
  end
end

class Position
  attr_accessor :board, :turn, :castling, :ep, :halfmove, :fullmove, :king
  def initialize
    @board = %w(- - - - - - - - - -
                - - - - - - - - - -
                - r n b q k b n r -
                - p p p p p p p p -
                - - - - - - - - - -
                - - - - - - - - - -
                - - - - - - - - - -
                - - - - - - - - - -
                - P P P P P P P P -
                - R N B Q K B N R -
                - - - - - - - - - -
                - - - - - - - - - -).map { |c| c == "-" ? nil : c }
    @turn = :white
    @castling = "KQkq"
    @ep = nil
    @halfmove = 0
    @fullmove = 1
    @king = { white: e1, black: e8 }
  end
  def initialize_copy(other)
    @board = other.board.dup
    @turn = other.turn
    @castling = other.castling.dup
    @ep = other.ep
    @halfmove = other.halfmove
    @fullmove = other.fullmove
    @king = other.king.dup
  end
  def to_s
    b = @board.each_slice(10).to_a[2..9].map { |row| row[1..8].map { |s| s || "-" }.join(" ") }.join("\n")
    c = castling.empty? ? :- : castling
    e = ep.nil? ? :- : ep.to_sq
    "#{b} #{turn} #{c} #{e} #{halfmove} #{fullmove}"
  end
  def white(w,b,t=turn)
    t == :white ? w : b
  end
  def bounded(idx)
    21 <= idx && idx <= 98 && idx%10 != 0 && idx%10 != 9
  end
  def find_repeat(piece, to, dirs, repeat)
    list = []
    dirs.each do |dir|
      if repeat
        from = to + dir
        while bounded(from)
          list.push(from) if board[from] == piece
          break if board[from]
          from += dir
        end
      else
        from = to + dir
        list.push(from) if board[from] == piece
      end
    end
    list
  end
  def find(piece,to)
    list = []
    color = "RNBQKP".include?(piece) ? :white : :black
    case piece
    when "N", "n" then list = find_repeat(piece, to, [-21,-19,-12,-8,8,12,19,21], false)
    when "R", "r" then list = find_repeat(piece, to, [-10,-1,1,10], true)
    when "K", "k" then list = find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], false)
    when "Q", "q" then list = find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], true)
    when "B", "b" then list = find_repeat(piece, to, [-11,-9,9,11], true)
    when "P", "p" then
      if board[to] || to == ep
        [11,9].each do |dir|
          from = to + white(dir,-dir,color)
          list.push(from) if board[from] == piece
        end
      else
        from = to + white(10,-10,color)
        list.push(from) if board[from] == piece
        from = to + white(20,-20,color)
        list.push(from) if board[from] == piece && to/10 == white(6,5,color) && board[(to+from)/2] == nil
      end
    end
    list
  end
  def in_check?
    white("rnbqkp","RNBQKP").chars.any? { |piece| !find(piece, king[turn]).empty? }
  end
  def move(str)
    list = []
    is_ep_capture = false
    is_capture = false
    if m = str.match(/^(?<piece>[RNBQK])? (?<col>[a-h])?(?<row>[1-8])? x?
                     (?<sq>[a-h][1-8]) (=(?<promote>[RNBQ]))? \+?$/x) then
      piece = m[:piece] || "P"
      piece.downcase! if turn == :black
      promote = m[:promote] if m[:promote]
      promote.downcase! if promote && turn == :black
      to = m[:sq].to_idx
      col = m[:col].ord - 'a'.ord + 1 if m[:col]
      row = '8'.ord - m[:row].ord + 2 if m[:row]
      list = find(piece,to)
      list.select! { |from| from%10 == col } if col
      list.select! { |from| from/10 == row } if row
      is_ep_capture = "Pp".include?(piece) && to == ep
      is_capture = board[to] || is_ep_capture
    elsif str == "O-O" && castling.include?(white("K","k"))
      piece = white("K", "k")
      to = white(g1,g8)
      list.push(white(e1,e8))
      board[white(f1,f8)] = board[white(h1,h8)]
      board[white(h1,h8)] = nil
      castling.delete(white("K","k"))
    elsif str == "O-O-O" && castling.include?(white("Q","q"))
      piece = white("K", "k")
      to = white(c1,c8)
      list.push(white(e1,e8))
      board[white(d1,d8)] = board[white(a1,a8)]
      board[white(a1,a8)] = nil
      castling.delete(white("Q","q"))
    end
    list.select! { |from|
      tmp = dup
      tmp.king[turn] = to if "Kk".include?(piece)
      tmp.board[to] = tmp.board[from]
      tmp.board[from] = nil
      !tmp.in_check?
    }
    raise IllegalMove.new(str,self,list) if list.size != 1
    from = list[0]
    @king[turn] = to if "Kk".include?(piece)
    board[ep + white(10,-10)] = nil if is_ep_capture
    @ep = "Pp".include?(piece) && to - from == white(-20,20) ? (to+from)/2 : nil
    board[to] = promote || board[from]
    board[from] = nil
    @fullmove += 1 if turn == :black
    if "Pp".include?(piece) || is_capture then
      @halfmove = 0
    else
      @halfmove += 1
    end
    @turn = white(:black, :white)
    self
  end
end

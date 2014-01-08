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
  def initialize(opts={})
    if opts.keys.any? { |k| k.size == 1 }
      @board = [nil]*(12*10)
      opts.each do |p,idx|
        next if p.size != 1
        @board[idx] = p
      end
    else
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
    end
    @turn = opts[:turn] || :white
    @castling = opts[:castling] || "KQkq"
    @ep = opts[:ep]
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
    @king = { white: @board.index("K"), black: @board.index("k") }
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
  def ==(other)
    @board == other.board &&
    @turn == other.turn &&
    @castling == other.castling &&
    @ep == other.ep &&
    @halfmove == other.halfmove &&
    @fullmove == other.fullmove
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
  def find_repeat(piece, to, dirs, repeat)
    list = []
    dirs.each do |dir|
      if repeat
        from = to + dir
        while 21 <= from && from <= 98 && from%10 != 0 && from%10 != 9
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
    case piece
    when "N", "n" then find_repeat(piece, to, [-21,-19,-12,-8,8,12,19,21], false)
    when "R", "r" then find_repeat(piece, to, [-10,-1,1,10], true)
    when "K", "k" then
      list = find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], false)
      if @board[to].nil?
        king_idx = king[turn]
        if to == white(g1,g8) && king_idx == white(e1,e8) then
          list.push(king_idx)
        end
      end
      list
    when "Q", "q" then find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], true)
    when "B", "b" then find_repeat(piece, to, [-11,-9,9,11], true)
    when "P", "p" then
      list = []
      color = piece == "P" ? :white : :black
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
      list
    end
  end
  def in_check?
    return false if king[turn].nil?
    white("rnbqkp","RNBQKP").chars.any? { |piece| !find(piece, king[turn]).empty? }
  end
  def move(*args)
    if args.size == 1
      str = args[0]
      list = []
    else
      str = ""
      list = [args[0]]
      to = args[1]
      piece = @board[list[0]]
    end
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
      tmp = self
      tmp_king = tmp.king[turn]
      tmp.king[turn] = to if "Kk".include?(piece)
      tmp_piece = tmp.board[to]
      tmp.board[to] = tmp.board[from]
      tmp.board[from] = nil
      is_in_check = tmp.in_check?
      tmp.board[from] = tmp.board[to]
      tmp.board[to] = tmp_piece
      tmp.king[turn] = tmp_king
      !is_in_check
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
  def possible_moves
    list = []
    pieces = white("RNBQKP", "rnbqkp")
    [*0..7].each do |i|
      [*0..7].each do |j|
        to = i + 1 + (j + 2)*10
        pieces.chars.each do |p|
          list += find(p,to).map { |from| [from, to] }
        end
      end
    end
    list
  end
  def evaluate
    score = 0
    score += @board.count("R")*5
    score += @board.count("N")*3
    score += @board.count("B")*3
    score += @board.count("Q")*9
    score += @board.count("P")*1
    score -= @board.count("r")*5
    score -= @board.count("n")*3
    score -= @board.count("b")*3
    score -= @board.count("q")*9
    score -= @board.count("p")*1
    score
  end
  def children
    possible_moves.map { |from, to|
      begin
        dup.move(from, to)
      rescue
        nil
      end
    }.compact
  end
end

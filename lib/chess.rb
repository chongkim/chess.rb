module ChessHelper
  'a'.upto('h').each.with_index do |file,f|
    8.downto(1).each.with_index do |rank,r|
      define_method("#{file}#{rank}") { f + r*8 }
    end
  end
  def white(piece,w,b)
    case piece
    when /^[A-Z]$/, :white then w
    when /^[a-z]$/, :black then b
    end
  end
  def to_sq(idx)
    y, x = idx.divmod(8)
    ((x + 'a'.ord).chr + ('8'.ord - y).chr).to_sym
  end
  def xydiff(from, to)
    [to%8 - from%8, to/8 - from/8]
  end
  def color(piece)
    case piece
    when /^[A-Z]$/ then :white
    when /^[a-z]$/ then :black
    end
  end
  def to_col(str)
    return nil if str.nil?
    str[0].ord - 'a'.ord
  end
  def to_row(str)
    return nil if str.nil?
    '8'.ord - str[-1].ord
  end
end

class Position
  attr_accessor :board, :turn, :castling, :ep, :halfmove, :fullmove
  INDICES = [*0..63]
  def initialize(opts={})
    @board = opts[:board] || %w(r n b q k b n r
                                p p p p p p p p
                                - - - - - - - -
                                - - - - - - - -
                                - - - - - - - -
                                - - - - - - - -
                                P P P P P P P P
                                R N B Q K B N R)
    @turn = opts[:turn] || :white
    @castling = opts[:castling] || %w(K Q k q)
    @ep = opts[:ep]
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
  end
  def initialize_copy(other)
    instance_variables.all? { |var|
      value = other.instance_variable_get(var)
      value = value.dup if value.is_a?(Array)
      self.instance_variable_set(var, value)
    }
  end
  def self.[](str,opts={})
    position = Position.new(opts.merge(:board => %w(-)*64))
    fn = :upcase
    str.split.each do |s|
      case s
      when /^([RNBQK])?([a-h][1-8])$/ then position.board[eval $2] = ($1 || "P").send(fn)
      when ".." then fn = :downcase
      end
    end
    position
  end
  def inspect
    b = @board.each_slice(8).map { |row| row.join.gsub(/-+/) { |s| s.size } }.join("/")
    t = white(turn,:w,:b)
    c = castling.empty? ? "-" : castling.join
    e = ep ? to_sq(ep) : "-"
    "#{b} #{t} #{c} #{e} #{halfmove} #{fullmove}"
  end
  def ==(other)
    instance_variables.all? { |var| self.instance_variable_get(var) == other.instance_variable_get(var) }
  end
  def path_clear(from, to)
    dx, dy = xydiff(from, to)
    return true if dx.abs != dy.abs && dx != 0 && dy != 0
    d = (dx <=> 0) + (dy <=> 0)*8
    (from+d).step(to-d, d).all? { |idx| board[idx] == "-" }
  end
  def in_check?
    list = INDICES.select { |idx| board[idx]==white(turn,"K","k") }
    return false if list.empty?
    king_idx = list[0]

    INDICES.any? { |from| dup.move_piece(from, king_idx) }
  end
  def move_pawn(from, to)
    piece = board[from]
    dx, dy = xydiff(from, to)

    if to == ep &&  dx.abs == 1 && dy == white(piece,-1,1) then # en passant
      board[ep + white(piece,8,-8)] = "-"
      return true
    else
      return (board[to] == '-' && dx == 0 && dy == white(piece,-1,1) || # move 1 square
              board[to] == '-' && dx == 0 && dy == white(piece,-2,2) && from/8 == white(piece, 6, 1) || # move 2 squares
              board[to] != '-' && dx.abs == 1 && dy == white(piece,-1,1)) # capture
    end
  end
  def move_king(from, to)
    piece = board[from]
    dx, dy = xydiff(from, to)
    if 1 < [dx.abs, dy.abs].max then
      if from == white(piece, e1, e8) && to == white(piece, g1, g8) && castling.include?(white(piece,"K","k"))
        move_piece(white(piece, h1, h8), white(piece, f1, f8))
      elsif from == white(piece, e1, e8) && to == white(piece, c1, c8) && castling.include?(white(piece, "Q", "q"))
        move_piece(white(piece, a1, a8), white(piece, d1, d8))
      else
        return false
      end
    end
    castling.delete(white(piece, "K", "k"))
    castling.delete(white(piece, "Q", "q"))
    return true
  end
  def move_rook(from, to)
    piece = board[from]
    dx, dy = xydiff(from, to)

    castling.delete(white(piece, "K", "k")) if from == h1
    castling.delete(white(piece, "Q", "q")) if from == a1
    return dx == 0 || dy == 0
  end
  def move_knight(from, to)
    dx, dy = xydiff(from, to)
    [dx.abs, dy.abs].sort == [1,2]
  end
  def move_bishop(from, to)
    dx, dy = xydiff(from, to)
    dx.abs == dy.abs
  end
  def move_queen(from , to)
    dx, dy = xydiff(from, to)
    dx.abs == dy.abs || dx == 0 || dy == 0
  end
  def move_piece(from, to)
    return nil if from == to

    piece = board[from]
    _, dy = xydiff(from, to)

    return nil if !path_clear(from, to)
    return nil if color(piece) == color(board[to])

    is_valid = case piece.upcase
               when "R" then move_rook(from, to)
               when "N" then move_knight(from,to)
               when "B" then move_bishop(from,to)
               when "Q" then move_queen(from,to)
               when "K" then move_king(from, to)
               when "P" then move_pawn(from, to)
               end
    board[to] = board[from]
    board[from] = "-"
    @ep = piece.upcase == "P" && dy.abs == 2 ? to + white(piece,8,-8) : nil
    is_valid && !in_check? ? self : nil
  end
  class IllegalMove < Exception
    def initialize(str, position)
      super("#{str}\n#{position}")
    end
  end
  class AmbiguousMove < Exception
    def initialize(str, position, list)
      super("#{str}\n#{position}#{list.map { |idx| to_sq(idx) }.inspect}")
    end
  end
  def to_s
    b = @board.map { |p|
      case p
      when "P" then "♙"
      when "p" then "♟"
      when "R" then "♖"
      when "r" then "♜"
      when "N" then "♘"
      when "n" then "♞"
      when "B" then "♗"
      when "b" then "♝"
      when "Q" then "♕"
      when "q" then "♛"
      when "K" then "♔"
      when "k" then "♚"
      else p
      end
    }.each_slice(8).map { |row| row.join(" ") }.join("\n")
    c = castling.empty? ? "-" : castling.join
    e = ep ? to_sq(ep) : "-"
    "#{b} #{turn} #{c} #{e} #{halfmove} #{fullmove}"
  end
  def move(str)
    position = self.dup
    if m = str.match(/^(?<piece>[RNBQK])?  (?<file>[a-h])?(?<rank>[1-8])?  x?  (?<sq>[a-h][1-8])  (=(?<promote>[RNBQ]))?  \+? $
                     |^(?<castle>O-O)$
                     |^(?<longcastle>O-O-O)$
                     /x) then
      to = m[:longcastle] ? white(turn,c1,c8) : m[:castle] ? white(turn,g1,g8) : eval(m[:sq])
      piece = m[:castle] || m[:longcastle] ? white(turn, "K", "k") : (m[:piece] || "P").send(white(turn, :upcase, :downcase))
      is_piece_taken = board[to] != '-' || piece.upcase == "P" && to == ep
      raise IllegalMove.new(str,self) if color(piece) != turn

      list = INDICES.select { |from|
        tmp = position.dup
        piece == tmp.board[from] && tmp.move_piece(from, to)
      }
      col = to_col(m[:file])
      row = to_row(m[:rank])
      list.select! { |from| from%8 == col } if col
      list.select! { |from| from/8 == row } if row
      raise IllegalMove.new(str,self) if list.empty?
      raise AmbiguousMove.new(str,self,list) if 1 < list.size

      position.move_piece(list[0], to)
      position.board[to] = m[:promote].send(white(piece,:upcase,:downcase)) if m[:promote] && piece.upcase == "P"
      position.turn = white(position.turn, :black, :white)
      position.fullmove += 1 if position.turn == :white
      position.halfmove += 1 if piece.upcase != "P" && !is_piece_taken
    else
      raise IllegalMove.new(str,self)
    end
    position
  end
end

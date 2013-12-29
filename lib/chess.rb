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
end

class Position
  attr_accessor :board, :turn, :castling, :ep, :halfmove, :fullmove
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
  def move_piece(from, to)
    piece = board[from]
    dx, dy = xydiff(from, to)

    return nil if !path_clear(from, to)
    return nil if color(piece) == color(board[to])

    case piece.upcase
    when "R" then
      return nil if dx != 0 && dy != 0
      castling.delete(white(piece, "K", "k")) if from == h1
      castling.delete(white(piece, "Q", "q")) if from == a1
    when "N" then return nil if [dx.abs, dy.abs].sort != [1,2]
    when "B" then return nil if dx.abs != dy.abs
    when "Q" then return nil if dx.abs != dy.abs && dx != 0 && dy != 0
    when "K" then
      if 1 < [dx.abs, dy.abs].max then
        if from == white(piece, e1, e8) && to == white(piece, g1, g8) && castling.include?(white(piece,"K","k"))
          move_piece(white(piece, h1, h8), white(piece, f1, f8))
        elsif from == white(piece, e1, e8) && to == white(piece, c1, c8) && castling.include?(white(piece, "Q", "q"))
          move_piece(white(piece, a1, a8), white(piece, d1, d8))
        else
          return nil
        end
      end
      castling.delete(white(piece, "K", "k"))
      castling.delete(white(piece, "Q", "q"))
    when "P"
      if to == ep &&  dx.abs == 1 && dy == white(piece,-1,1) then
        board[ep + white(piece,8,-8)] = "-"
      elsif dx == 0 then
        return nil if dy.abs != 1 && (dy.abs != 2 || from/8 != white(piece, 6, 1))
        return nil if board[to] != '-'
      elsif dx.abs == 1 && dy == white(piece,-1,1) && to != '-'
        # capturing a piece
      else
        return nil
      end
    end
    board[to] = board[from]
    board[from] = "-"
    @ep = piece.upcase == "P" && dy.abs == 2 ? to + white(piece,8,-8) : nil
    self
  end
end

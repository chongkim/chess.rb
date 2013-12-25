module ChessHelper
  def to_idx(sq)
    return sq if sq.is_a?(Fixnum)
    sq[0].ord - 'a'.ord + ('8'.ord - sq[1].ord)*8
  end
  def color(piece)
    case piece
    when /^[A-Z]$/ then :white
    when /^[a-z]$/ then :black
    end
  end
  def xydiff(source_idx, target_idx)
    [target_idx%8 - source_idx%8, target_idx/8 - source_idx/8]
  end
  def to_sq(idx)
    return idx.to_sym if !idx.is_a?(Fixnum)
    y, x = idx.divmod(8)
    ((x + 'a'.ord).chr + ('8'.ord - y).chr).to_sym
  end
end

class Position
  attr_accessor :board, :turn, :ep, :castling, :halfmove, :fullmove
  INDICES = [*0..63]
  def initialize(opts={})
    @board = %w(-)*64
    opts = { :turn => opts } if opts.is_a?(Symbol)
    @turn = opts[:turn] || :white
    @ep = opts[:ep]
    @castling = opts[:castling] || %w(K Q k q)
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
  end
  def [](idx)
    board[to_idx(idx)]
  end
  def self.[](str, *args)
    position = Position.new(*args)
    fn = :upcase
    str.split.each do |s|
      case s
      when /^([RNBQK])?([a-h][1-8])$/ then position.board[to_idx($2)] = ($1 || "P").send(fn)
      when ".." then fn = :downcase
      end
    end
    position
  end
  def path_clear(source_idx, target_idx)
    dx, dy = xydiff(source_idx, target_idx)
    return true if dx.abs != dy.abs && dx != 0 && dy != 0
    d = (dx <=> 0) + (dy <=> 0)*8
    (source_idx + d).step(target_idx - d, d).all? { |idx| board[idx] == "-" }
  end
  def white(w,b)
    turn == :white ? w : b
  end
  def find(piece, target_sq)
    target_idx = to_idx(target_sq)
    target_piece = board[target_idx]
    list = INDICES.select do |source_idx|
      next if board[source_idx] != piece || color(target_piece) == color(piece)
      dx, dy = xydiff(source_idx, target_idx)
      case piece.upcase
      when "R" then dx == 0 || dy == 0
      when "N" then [dx.abs, dy.abs].sort == [1,2]
      when "B" then dx.abs == dy.abs
      when "Q" then dx.abs == dy.abs || dx == 0 || dy == 0
      when "K" then [dx.abs, dy.abs].max <= 1
      when "P" then
        (dx == 0 && dy == white(-1,1) && target_piece == "-") ||   # move 1 square
          (dx == 0 && dy == white(-2,2) && source_idx/8 == white(6,1)) ||  # move 2 squares
          (dx.abs == 1 && dy == white(-1,1) && target_piece != '-' ) || # capture a piece
          (dx.abs == 1 && dy == white(-1,1) && to_sq(target_sq) == ep) # en passant
      end && path_clear(source_idx, target_idx)
    end
    target_sq.is_a?(Symbol) ? list.map { |idx| to_sq(idx) } : list
  end
end

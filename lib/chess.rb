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
    opts = { :turn => opts } if opts.is_a?(Symbol)
    @board = opts[:board] || %w(-)*64
    @turn = opts[:turn] || :white
    @ep = opts[:ep]
    @castling = opts[:castling] || %w(K Q k q)
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
  end
  def initialize_copy(other)
    instance_variables.each do |ivar|
      value = other.instance_variable_get(ivar)
      value = value.dup if value.is_a?(Array)
      self.instance_variable_set(ivar, value)
    end
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
    source_idx = to_idx(source_idx)
    target_idx = to_idx(target_idx)

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
  def self.setup
    Position.new(:board => %w(r n b q k b n r
                              p p p p p p p p
                              - - - - - - - -
                              - - - - - - - -
                              - - - - - - - -
                              - - - - - - - -
                              P P P P P P P P
                              R N B Q K B N R))
  end
  def []=(idx,value)
    board[to_idx(idx)] = value
  end
  class IllegalMove < Exception
    def initialize(str, position)
      super("#{str}\n#{position}")
    end
  end
  def move_piece(source_idx, target_idx)
    source_idx = to_idx(source_idx)
    target_idx = to_idx(target_idx)
    board[target_idx] = board[source_idx]
    board[source_idx] = "-"
  end
  class AmbiguousMove < IllegalMove; end
  def to_s
    @board.each_slice(8).map { |row| row.join(" ") }.join("\n")
  end
  def enpassant_value(piece, source_idx, target_idx)
    (piece.upcase == "P" && 8 < (target_idx-source_idx).abs) ? to_sq(source_idx - white(8,-8)) : nil
  end
  def move(str)
    illegal = IllegalMove.new(str,self)
    position = self.dup
    if m = str.match(/^(?<piece>[RNBQK])?(?<file>[a-h])?x?(?<sq>[a-h][1-8])\+?$/)
      target_idx = to_idx(m[:sq])
      piece = (m[:piece] || "P").send(white(:upcase, :downcase))
      list = find(piece, target_idx)
      raise illegal if list.empty?
      raise ambiguous if 1 < list.size
      source_idx = list[0]
      position.move_piece(source_idx, target_idx)
    elsif str == "O-O"
      piece = "K".send(white(:upcase,:downcase))
      raise illegal if !castling.include?(white("K","k"))
      raise illegal if !path_clear(white(:e1,:e8),white(:h1,:h8))
      position.move_piece(white(:e1,:e8), white(:g1,:g8))
      position.move_piece(white(:h1,:h8), white(:f1,:f8))
    else
      raise illegal
    end
    position.ep = enpassant_value(piece, source_idx, target_idx)
    position.fullmove += 1 if turn == :black
    position.halfmove += 1 if piece.upcase != "P"
    position.turn = white(:black, :white)
    position
  end
end

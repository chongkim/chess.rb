require "debugger"

module ChessHelper
  ('a'..'h').each.with_index do |col,i|
    (1..8).each.with_index do |row,j|
      define_method("#{col}#{row}") { i + 1 + (8 - j + 1)*10 }
    end
  end
end

class Array
  def to_idx
    self[0] + 1 + (self[1] + 2)*10
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
class Symbol
  def color
    return @color unless @color.nil?
    @color = :a < self ? :black : :white
  end
  def pawn?
    self == :P || self == :p
  end
  def king?
    self == :K || self == :k
  end
end

class IllegalMove < Exception
  def initialize(str, position, list)
    super("#{str}\n#{position}" + (list.empty? ? "" : list.map { |from| from.to_sq }.inspect))
  end
end

class Position
  include ChessHelper
  attr_accessor :board, :turn, :castling, :ep, :halfmove, :fullmove, :king
  def initialize(opts={})
    if opts.keys.any? { |k| k.size == 1 }
      @board = [nil]*(12*10)
      opts.each do |p,idxs|
        next if p.size != 1
        idxs = [idxs] unless Array === idxs
        idxs.each do |idx|
          @board[idx] = p
        end
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
                  - - - - - - - - - -).map { |c| c == "-" ? nil : c.to_sym }
    end
    @turn = opts[:turn] || :white
    @castling = opts[:castling] || castling_default
    @ep = opts[:ep]
    @halfmove = opts[:halfmove] || 0
    @fullmove = opts[:fullmove] || 1
    @king = { white: @board.index(:K), black: @board.index(:k) }
  end

  def castling_default
    str = ""
    str += "K" if board[e1] == :K && board[h1] == :R
    str += "Q" if board[e1] == :K && board[a1] == :R
    str += "k" if board[e8] == :k && board[h8] == :r
    str += "q" if board[e8] == :k && board[a8] == :r
    str
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

  def self.[](opts)
    Position.new(opts)
  end

  def ==(other)
    self.class == other.class &&
    @board == other.board &&
    @turn == other.turn &&
    @castling == other.castling &&
    @ep == other.ep &&
    @halfmove == other.halfmove &&
    @fullmove == other.fullmove
  end

  def inspect
    b = @board.each_slice(10).to_a[2..9].map { |row| row[1..8].map { |s| s || "-" }.join.gsub(/-+/) { |s| s.size } }.join("/")
    t = white(:w,:b)
    c = castling.empty? ? :- : castling
    e = ep.nil? ? :- : ep.to_sq
    "#{b} #{t} #{c} #{e} #{halfmove} #{fullmove}"
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

  def promote_str(promote)
    if promote
      "=#{promote}"
    else
      ""
    end
  end

  def move_str(from, to, promote=nil)
    piece = board[from]
    piece_str = piece.pawn? ? "" : piece.to_s
    piece_str.upcase! if piece.color == :black
    list = find(piece, to)
    is_capture = board[to] || piece.pawn? && to == ep
    if piece.pawn? && is_capture then
      possible_pawn_pos = [*0..7].select { |row| board[from%10 + (row+2)*10] == piece }
      possible_pawn_pos.select! { |row|
        target = board[to%10 + (row+2+white(-1,1))*10];
        target && target.color != piece.color ||
          piece.pawn? && to == ep && row+2 == from/10
      }
      if possible_pawn_pos.size == 1 then
        "#{from.to_sq[0]}#{to.to_sq[0]}#{promote_str(promote)}"
      else
        "#{from.to_sq[0]}#{to.to_sq}#{promote_str(promote)}"
      end
    elsif piece.king? && to - from == 2
      "O-O"
    elsif piece.king? && to - from == -2
      "O-O-O"
    else
      if list.size == 1 then
        "#{piece_str}#{to.to_sq}#{promote_str(promote)}"
      elsif list.select { |idx| idx%10 == from%10 }.size == 1
        "#{piece_str}#{from.to_sq[0]}#{to.to_sq}#{promote_str(promote)}"
      elsif list.select { |idx| idx/10 == from/10 }.size == 1
        "#{piece_str}#{from.to_sq[1]}#{to.to_sq}#{promote_str(promote)}"
      else
        "#{piece_str}#{from.to_sq}#{to.to_sq}#{promote_str(promote)}"
      end
    end
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
    when :N, :n then find_repeat(piece, to, [-21,-19,-12,-8,8,12,19,21], false)
    when :R, :r then find_repeat(piece, to, [-10,-1,1,10], true)
    when :K, :k then
      list = find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], false)
      if @board[to].nil?
        king_idx = king[turn]
        if king_idx == white(e1,e8) && (to - king_idx).abs == 2
          if to == white(g1,g8) && castling.include?(white("K", "k")) then
            list.push(king_idx) if board[white(f1,f8)].nil? && board[white(g1,g8)].nil?
          elsif to == white(c1,c8) && castling.include?(white("Q", "q")) then
            list.push(king_idx) if board[white(b1,b8)].nil? && board[white(c1,c8)].nil? && board[white(d1,d8)].nil?
          end
        end
      end
      list
    when :Q, :q then find_repeat(piece, to, [-11,-10,-9,-1,1,9,10,11], true)
    when :B, :b then find_repeat(piece, to, [-11,-9,9,11], true)
    when :P, :p then
      list = []
      color = piece == :P ? :white : :black
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
    white([:r,:n,:b,:q,:k,:p],[:R,:N,:B,:Q,:K,:P]).any? { |piece| !find(piece, king[turn]).empty? }
  end

  def move(*args)
    if args.size == 1
      str = args[0]
      list = []
    else
      str = ""
      from = args[0]
      list = [from]
      to = args[1]
      promote = args[2]
      piece = @board[list[0]]
      if piece.king? then
        if to - from == 2 then
          @board[white(f1,f8)] = @board[white(h1,h8)]
          @board[white(h1,h8)] = nil
        end
        if to - from == -2 then
          @board[white(d1,d8)] = @board[white(a1,a8)]
          @board[white(a1,a8)] = nil
        end
        castling.delete!(white("K","k"))
        castling.delete!(white("Q","q"))
      end
      if piece.pawn? && to == ep then
        @board[ep + white(10,-10)] = nil
      end
    end
    is_ep_capture = false
    is_capture = false
    if m = str.match(/^(?<piece>[RNBQK])? (?<col>[a-h])?(?<row>[1-8])? x?
                     (?<sq>[a-h][1-8]) (=(?<promote>[RNBQ]))? \+?$/x) then
      piece = m[:piece] || "P"
      piece.downcase! if turn == :black
      piece = piece.to_sym
      promote = m[:promote] if m[:promote]
      promote.downcase! if promote && turn == :black
      promote = promote.to_sym if promote
      to = m[:sq].to_idx
      col = m[:col].ord - 'a'.ord + 1 if m[:col]
      row = '8'.ord - m[:row].ord + 2 if m[:row]
      list = find(piece,to)
      list.select! { |_from| _from%10 == col } if col
      list.select! { |_from| _from/10 == row } if row
      is_ep_capture = piece.pawn? && to == ep
      is_capture = board[to] || is_ep_capture
    elsif str == "O-O" && castling.include?(white("K","k"))
      piece = white(:K, :k)
      to = white(g1,g8)
      list.push(white(e1,e8))
      board[white(f1,f8)] = board[white(h1,h8)]
      board[white(h1,h8)] = nil
      castling.delete(white("K","k"))
    elsif str == "O-O-O" && castling.include?(white("Q","q"))
      piece = white(:K, :k)
      to = white(c1,c8)
      list.push(white(e1,e8))
      board[white(d1,d8)] = board[white(a1,a8)]
      board[white(a1,a8)] = nil
      castling.delete(white("Q","q"))
    end
    list.select! { |_from|
      tmp = self
      tmp_king = tmp.king[turn]
      tmp.king[turn] = to if piece.king?
      tmp_piece = tmp.board[to]
      tmp.board[to] = tmp.board[_from]
      tmp.board[_from] = nil
      is_in_check = tmp.in_check?
      tmp.board[_from] = tmp.board[to]
      tmp.board[to] = tmp_piece
      tmp.king[turn] = tmp_king
      !is_in_check
    }
    raise IllegalMove.new(str,self,list) if list.size != 1
    from = list[0]
    @king[turn] = to if piece.king?
    board[ep + white(10,-10)] = nil if is_ep_capture
    @ep = piece.pawn? && to - from == white(-20,20) ? (to+from)/2 : nil
    board[to] = promote || board[from]
    board[from] = nil
    @fullmove += 1 if turn == :black
    if piece .pawn?|| is_capture then
      @halfmove = 0
    else
      @halfmove += 1
    end
    @turn = white(:black, :white)
    self
  end

  def possible_moves
    list = []
    pieces = white([:R,:N,:B,:Q,:K,:P], [:r,:n,:b,:q,:k,:p])
    [*0..7].each do |i|
      [*0..7].each do |j|
        to = i + 1 + (j + 2)*10
        pieces.each do |p|
          list += find(p,to).flat_map { |from|
            begin
              dup.move(from, to)
              if p.king? && (to - from).abs == 2 && dup.move(from, (to+from)/2).in_check?
                raise IllegalMove.new("",self,[])
              end
              result = []
              item = [from, to] unless (board[to] && board[to].color == p.color ||
                                          p.king? && (to - from).abs == 2 && in_check?)
              if item && p.pawn? && to/10 == white(2,9)
                result = white([:R,:N,:B,:Q],[:r,:n,:b,:q]).map { |promote|
                  [from, to, promote]
                }
              else
                result = [item]
              end
              result
            rescue IllegalMove
              nil
            end
          }.compact
        end
      end
    end
    list
  end

  def possible_moves_str
    possible_moves.map { |from, to, promote| move_str(from, to, promote) }
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

  def checkmate?
    in_check? && possible_moves.empty?
  end

  def stalemate?
    !in_check? && possible_moves.empty?
  end

  def evaluate
    score = 0
    score += board.count(:R)*5
    score += board.count(:N)*3
    score += board.count(:B)*3
    score += board.count(:Q)*9
    score += board.count(:P)*1
    score -= board.count(:r)*5
    score -= board.count(:n)*3
    score -= board.count(:b)*3
    score -= board.count(:q)*9
    score -= board.count(:p)*1
    if fullmove < 10 then
      [e4,e5,d4,d5].each do |idx|
        [:R,:N,:B,:Q,:K,:P].each { |p| score += find(p,idx).size * 0.1 }
        [:r,:n,:b,:q,:k,:p].each { |p| score -= find(p,idx).size * 0.1 }
      end
    else
      white_king_idx = board.index(:K)
      black_king_idx = board.index(:k)
      [:r,:n,:b,:q,:k,:p].each { |p| score -= find(p,white_king_idx).size * 0.1 } if white_king_idx
      [:R,:N,:B,:Q,:K,:P].each { |p| score += find(p,black_king_idx).size * 0.1 } if black_king_idx
    end
    score
  end

  def minimax(depth=1)
    if checkmate? then
      return white(-100,100)
    elsif possible_moves.empty? || halfmove >= 100
      return 0
    elsif depth > 2
      return evaluate
    end
    values = possible_moves.map { |mv| dup.move(*mv).minimax(depth+1) }.compact
    values.send(white(:max,:min)) + white(-depth,+depth) unless values.empty?
  end

  def best_move
    possible_moves.send(white(:max_by, :min_by)) { |mv| dup.move(*mv).minimax }
  end

  def game_end?
    checkmate? || possible_moves.empty? || halfmove >= 100
  end
end

require "gosu"
require "./lib/chess.rb"

class Chess < Gosu::Window
  attr_accessor :width, :height, :cwidth, :position, :font, :from, :to, :player
  PIECES = {R: '♖', N: '♘', B: '♗', Q: '♕',K: '♔',P:'♙',r:'♜',n:'♞',b:'♝',q:'♛',k:'♚',p: '♟'}
  def initialize
    @cwidth = 100
    @width = cwidth*8
    @height = cwidth*8
    super(width,height,false)
    @position = Position.new
    @font = Gosu::Font.new(self, Gosu::default_font_name, cwidth)
  end

  def needs_cursor?
    true
  end

  def get_idx
    [mouse_x.to_i/cwidth, mouse_y.to_i/cwidth].to_idx
  end

  def button_down(id)
    close if id == Gosu::KbQ
    @from = get_idx if id == Gosu::MsLeft
  end

  def button_up(id)
    if id == Gosu::MsLeft then
      @to = get_idx
      if position.possible_moves.include?([from, to])
        position.move(from, to)
        @player = :computer_wait
      end
    end
  end

  def update
    case player
    when :computer_wait then @player = :computer
    when :computer then
      if !position.game_end? then
        puts "computer starts"
        best = position.best_move
        position.move(*best)
        puts "comptuer ends"
      end
      @player = :human
    end
  end

  def draw
    x = 0
    y = 0
    light = Gosu::Color::argb(0xff,0xc0,0xc0,0xc0)
    dark = Gosu::Color::argb(0xff,0x50,0x90,0x50)
    (0..7).each do |i|
      (0..7).each do |j|
        color = (i+j)%2==0 ? light : dark
        x = i*cwidth
        y = j*cwidth
        draw_quad(x,y,color,
                  x+cwidth,y,color,
                  x+cwidth,y+cwidth,color,
                  x,y+cwidth,color)
        piece = position.board[[i,j].to_idx]
        str = PIECES[piece] || ""
        cx = (cwidth - font.text_width(str))/2
        font.draw(str,x+cx,y,1,1,1,Gosu::Color::BLACK)
      end
    end
  end
end

chess = Chess.new
chess.show

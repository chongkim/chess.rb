#!/usr/bin/env ruby

require "./lib/chess"
require "gosu"

class Game < Gosu::Window
  attr_accessor :width, :cwidth
  def initialize
    @cwidth = 100
    @width = @cwidth*8
    super(width, width, false)
    @position = Position.new
    @dark = Gosu::Color.argb(0xff, 0x20, 0x80, 0x20)
    @light = Gosu::Color.argb(0xff, 0xa0, 0xa0, 0x80)
    @black = Gosu::Color::BLACK
    @white = Gosu::Color::WHITE
    @font = Gosu::Font.new(self, Gosu::default_font_name, cwidth)
  end
  def button_down(id)
    close if id == Gosu::KbQ
    @from = mouse_x.to_i/cwidth + mouse_y.to_i/cwidth * 8 if Gosu::MsLeft
  end
  def button_up(id)
    if Gosu::MsLeft then
      to = mouse_x.to_i/cwidth + mouse_y.to_i/cwidth * 8
      @position.move(@from, to)
    end
  end
  def needs_cursor?
    true
  end
  def update
    if @position.turn == :black && !@position.game_end? then
      mv = @position.best_move
      @position.move(*mv)
    end
  end
  def draw
    (0..7).each do |i|
      (0..7).each do |j|
        color = (i+j)%2 == 0 ? @light : @dark
        translate(i*cwidth, j*cwidth) do
          draw_quad(0,0,color,
                    0,cwidth,color,
                    cwidth, cwidth, color,
                    cwidth, 0, color)
          idx = i + j*8
          pieces = {R:'♜',N:'♞',B:'♝',Q:'♛',K:'♚',P:'♟'}
          piece = @position[idx]
          @font.draw(pieces[piece.upcase] || "", 0, 0, 1, 1, 1, piece.color == :black ? @black : @white)
        end
      end
    end
  end
end

game = Game.new
game.show

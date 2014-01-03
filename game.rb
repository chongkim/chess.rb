require "./lib/chess"

position = Position.new
puts position
while str = gets.chomp
  position.move(str)
  puts "", position, str
  from, to = position.possible_moves.sample
  position.move("#{from.to_sq}-#{to.to_sq}")
  puts "", position, "#{from.to_sq} #{to.to_sq}"
end

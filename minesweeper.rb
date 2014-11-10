require 'yaml'

class Tile
  attr_reader :revealed, :flagged, :neighbors

  attr_accessor :bomb

  NEIGHBORS = [[ 1, -1],
               [ 0, -1],
               [-1, -1],
               [-1,  0]]

  def initialize(position, board)
    @revealed = false
    @flagged = false
    @bomb = false
    @neighbors = []
    assign_neighbors(position, board)
  end

  def reveal #game over if bomb
    @revealed = true
    @flagged = false

    if neighbor_bomb_count == 0
      neighbors.each do |neighbor|
        next if neighbor.revealed
        neighbor.reveal
      end
    end

    nil
  end

  def flag
    if @flagged
      @flagged = false
    else
      @flagged = true
    end

    nil
  end

  def add_neighbors(tile)
    @neighbors << tile unless @neighbors.include?(tile) #depending
    tile.neighbors << self unless tile.neighbors.include?(self)
  end

  def neighbor_bomb_count
    @neighbors.inject(0) {|count,tile| tile.bomb ? count + 1 : count }
  end

  def assign_neighbors(position, board)
    xlen = board[0].size
    ylen = board.size
    x,y = position

    NEIGHBORS.each do |disp|
      dx, dy = disp
      x_new, y_new = x + dx, y + dy
      next unless x_new.between?(0,xlen-1) && y_new.between?(0,ylen-1)
      neighbor_tile = board[y_new][x_new]
      self.add_neighbors(neighbor_tile)
    end

    nil
  end
end

class Board
  X_LEN = 9 #Board.X_LEN
  Y_LEN = 9
  N_BOMB = 10

  attr_reader :game_won, :game_lost

  def initialize
    @board = Array.new(Y_LEN) {Array.new(X_LEN)}
    assign_bombs  # [[nil,:bomb,nil, etc],[]]
    tile_board
    @game_lost = false
    @game_won = false
  end

  def tile_board
    Y_LEN.times do |y|
      X_LEN.times do |x|
        value = @board[y][x]
        @board[y][x] = Tile.new([x,y], @board)
        @board[y][x].bomb = true if value == :bomb
      end
    end

    nil
  end

  def assign_bombs
    bomb_index = []

    until bomb_index.size == N_BOMB
      x = rand(X_LEN)
      y = rand(Y_LEN)
      pos = [x,y]
      bomb_index << pos unless bomb_index.include?(pos)
    end

    bomb_index.each do |bomb|
      x, y = bomb
      @board[y][x] = :bomb
    end

    nil
  end

  def handle_choice(flag_reveal,pos)
    x,y = pos
    tile = @board[y][x]

    if flag_reveal == 'f'
      tile.flag
    else
      tile.reveal

      @game_lost = true if tile.bomb

      check_if_game_won
    end

    nil
  end

  def check_if_game_won
    @board.flatten.all? {|tile| tile.revealed || tile.bomb}
  end

  def display_board
    @board.each do |row|
      row.each do |tile|
        if tile.bomb && (@game_lost || @game_won)
          print "B"
          next
        end

        print "*" unless tile.revealed || tile.flagged
        print "F" if tile.flagged
        bomb_count = tile.neighbor_bomb_count
        print "_" if tile.revealed && bomb_count == 0 && !tile.bomb
        print bomb_count if tile.revealed && bomb_count > 0

      end
      puts ""
    end
  end

end

class Game
  attr_reader :board

  def ask_user_if_loading_savegame

  end

  def initialize(filename = '')
    unless filename == ''
      var = File.readlines(filename).join
      @board = YAML::load(var)
    else
      @board = Board.new
    end
  end

  def play
    loop do #same as while true
      system('clear')
      @board.display_board

      #user input
      save_option
      flag_reveal = choose_flag_reveal
      pos = choose_square

      #handle input
      @board.handle_choice(flag_reveal, pos)

      break if @board.game_lost || @board.game_won
    end

    system('clear')
    if @board.game_lost
      puts "You lost :("
    else
      puts "You won!!!!!"
    end
    @board.display_board

    nil
  end

  def save_option
    puts "Save board? Y/N"
    answer = gets.chomp.upcase == "Y"
    if answer
      saved_board = @board.to_yaml
      File.open('saved_game.txt', 'w') do |f|
        f.puts(saved_board)
      end
    end

    nil
  end

  def choose_flag_reveal
    begin
      puts "Write 'f' for flag, 'r' for reveal"
      result = gets.chomp
      raise InvalidEntryError unless ['f','r'].include?(result)
    rescue InvalidEntryError
      puts 'You entered a wrong letter'
      retry
    end

    result
  end

  def choose_square
    xlen = Board::X_LEN
    ylen = Board::Y_LEN

    begin
      puts "Choose row"
      row = Integer(gets.chomp)
      puts "Choose column"
      col = Integer(gets.chomp)
      raise InvalidEntryError unless col.between?(0,xlen-1) && row.between?(0,ylen-1)

    rescue ArgumentError
      puts "You didn't enter a number"
      retry
    rescue InvalidEntryError
      puts 'You are off the board'
      retry
    end

    [col,row]
  end
end

class InvalidEntryError < StandardError
end

if __FILE__ == $PROGRAM_NAME
  puts "If you want to load from save game"
  puts "enter save file name, otherwise just press enter"
  filename = gets.chomp
  Game.new(filename).play
end


#Game.new.play




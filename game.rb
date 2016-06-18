require_relative "square"

class Game
  def initialize window
    @window = window
    @squares = random_squares(([:red, :green, :blue] * 12).shuffle)
    @font = Gosu::Font.new(36)
    @end_game = false
  end

  def draw
    draw_end_screen if @end_game
    draw_game_board
  end

  def handle_mouse_move x, y
    row = (y.to_i - 20) / 100
    column = (x.to_i - 20) / 100
    @current_square = get_square(column, row)
  end

  def handle_mouse_down x, y
    @start_square = get_square(pixel_to_coord(x), pixel_to_coord(y))
  end

  def handle_mouse_up x, y
    @end_square = get_square(pixel_to_coord(x), pixel_to_coord(y))
    move(@start_square, @end_square) if @start_square && @end_square
    @start_square = nil
    @end_game = true if game_over?
  end

  def get_square column, row
    @squares[row * 6 + column] unless !(0..5).include?(column) || !(0..5).include?(row)
  end

  def squares_between square1, square2
    if square1.row == square2.row
      squares_between_in_row(square1, square2)
    elsif square1.column == square2.column
      squares_between_in_column(square1, square2)
    end
  end

  def squares_between_in_row square1, square2
    Range.new(*[square1.column, square2.column].minmax).map do |column|
      get_square(column, square1.row)
    end.reject { |square| square.number == 0 }
  end

  def squares_between_in_column square1, square2
    Range.new(*[square1.row, square2.row].minmax).map do |row|
      get_square(square1.column, row)
    end.reject { |square| square.number == 0 }
  end

  def move square1, square2
    return unless move_is_legal?(square1, square2)
    color = @legal_squares[0].color
    number = @legal_squares[0].number + @legal_squares[1].number
    @legal_squares[0].clear and @legal_squares[1].clear and @legal_squares.clear
    square2.set(color, number)
  end

  def move_is_legal? square1, square2
    return false if square1.number == 0
    return false unless @legal_squares = squares_between(square1, square2)
    return false if @legal_squares.count != 2
    return false if @legal_squares[0].color != @legal_squares[1].color
    true
  end

  def legal_move_for? start_square
    return false if start_square.number == 0
    @squares.map { |end_square| move_is_legal?(start_square, end_square) }.any?
  end

  def game_over?
    !@squares.map { |square| legal_move_for?(square) }.any?
  end

  private

  def random_squares color_list
    (0..5).flat_map do |row|
      (0..5).map do |column|
        Square.new(@window, column, row, color_list.pop)
      end
    end
  end

  def pixel_to_coord n
    (n.to_i - 20) / 100
  end

  def draw_end_screen
    c = Gosu::Color.argb(0x33000000)
    @window.draw_quad(0, 0, c, 640, 0, c, 640, 640, c, 0, 640, c, 4)
    @font.draw("Game Over", 230, 240, 5)
    @font.draw("CTRL-R to Play Again", 205, 320, 5, 0.6, 0.6)
  end

  def draw_game_board
    @squares.each { |square| square.draw }
    return unless @start_square
    @start_square.highlight(:start)
    return unless @current_square && @current_square != @start_square
    @current_square.highlight(move_is_legal?(@start_square, @current_square) ? :legal : :illegal)
  end
end

class Wall
  attr_reader :parents
  attr_accessor :solid

  def initialize(parent, direction)
    @parents = {}
    if parent.class != Cell
      puts "Error: Wall::initialize: parent |#{parent}| was not a Cell"
      abort
    end
    @parents[direction] = parent
    other = parent.get_adjacent(opposite_direction(direction))
    if other && other.class != Cell
      puts "Error: Wall::initialize: other_parent |#{other_parent}| was not a Cell"
      abort
    end
    @parents[opposite_direction(direction)] = other
    @solid = true
  end

  def give_parent(parent, direction)
    if parent.class != Cell
      puts "Error: Wall::give_parent: parent |#{parent}| was not a Cell"
      abort
    end
    @parents[direction] = parent
  end

  def to_s
    @solid ? "#" : " "
  end

  def horizontal?
    # puts "@parents: |#{@parents}|"
    (parents[:left] || parents[:right]) ? true : false
  end

  def vertical?
    !self.horizontal?
  end

  def ur_parent
    parents[:up] || parents[:right]
  end

  def dl_parent
    parents[:down] || parents[:left]
  end

  def parents_in_maze
    get = [] #TODO dat name
    parents.each do |dir, parent|
      get << parent if parent && parent.in_maze
    end
    get
  end

  def other_parent(parent_a)
    found = false
    other = nil
    parents.each do |dir, parent|
      other = parent if parent != parent_a
      found = true if parent == parent_a
    end
    if found
      return other
    else
      puts "The supplied parent #{parent_a} wasn't even a parent!"
    end
  end
end

class Cell
  attr_reader :x, :y, :walls, :group
  attr_accessor :in_maze

  def initialize(x,y)
    @x = x
    @y = y
    @walls = {}
    @in_maze = false
    set_walls
  end

  def set_walls
    $directions.each do |direction|
      adj = get_adjacent(direction)
      if adj
        @walls[direction] = get_adjacent(direction).walls[opposite_direction(direction)]
        @walls[direction].give_parent(self, opposite_direction(direction))
      else
        @walls[direction] ||= Wall.new(self, opposite_direction(direction))
      end
    end
  end

  def to_s
    "#{@x},#{@y}"
  end

  def draw_big
    # TODO
  end

  def draw_small
    # TODO
  end

  def get_adjacent(dir)
    case dir
    when :up
      $maze[[@x, @y-1]]
    when :down
      $maze[[@x, @y+1]]
    when :left
      $maze[[@x-1, @y]]
    when :right
      $maze[[@x+1, @y]]
    end
  end

  def remove_wall(dir)
    @walls[dir].solid = false
  end

  def neighbor_dirs
    $directions.select do |direction|
      self.get_adjacent(direction) 
    end
  end

  def neighbors
    neighbor_dirs.map do |direction|
      self.get_adjacent(direction)
    end
  end

  def random_neighbor
    self.neighbors.shuffle.first
  end

  def neighbors_not_in_maze
    self.neighbors.select do |neighbor|
      !neighbor.in_maze
    end
  end

  def dir_to_neighbor(neighbor)
    $directions.each do |dir|
      return dir if get_adjacent(dir) == neighbor
    end
  end

end

$directions = [
  :up,
  :down,
  :left,
  :right
]

$rng = Random.new()

def opposite_direction (dir)
  case dir
  when :up
    :down
  when :down
    :up
  when :left
    :right
  when :right
    :left
  end
end

def show_maze_big
  $h.times do |y|
    top = ""
    mid = ""
    bot = ""
    $l.times do |x|
      top += "#"
      top += "#{$maze[[x,y]].walls[:up]}"
      top += "#"
      mid += "#{$maze[[x,y]].walls[:left]}"
      mid += " "
      mid += "#{$maze[[x,y]].walls[:right]}"
      bot += "#"
      bot += "#{$maze[[x,y]].walls[:down]}"
      bot += "#"
    end
    puts top
    puts mid
    puts bot
  end
end

def show_maze_small
  (($l*2)+1).times do |_|
    print "#"
  end
  puts
  $h.times do |y|
    mid = "#"
    bot = "#"
    $l.times do |x|
      mid += " "
      mid += "#{$maze[[x,y]].walls[:right]}"
      bot += "#{$maze[[x,y]].walls[:down]}"
      bot += "#"
    end
    puts mid 
    puts bot
  end
end

def random_cell
  $maze[[$rng.rand($l),$rng.rand($h)]]
end

def make_maze(type)
  puts "Size of #{type} maze (l w): "
  length, height = gets.split(" ")
  puts "Horizontal tendency: (h): "
  ht = gets 
  $l = length.to_i
  $h = height.to_i
  $ht = ht.to_i
  $ht = 1 if $ht < 1
  $maze = {}
  $l.times do |x|
    $h.times do |y|
      $maze[[x,y]] = Cell.new(x,y)
    end
  end
end

def cells_adj_side(cell_1, cell_2)
  cell_1.x == cell_2.x ? true : false
end


def binary_tree
  make_maze("Binary Tree")
  ($l).times do |x|
    ($h).times do |y|
      if x == $l-1 && y == $h-1
      elsif x == $l-1
        $maze[[x,y]].remove_wall(:down)
      elsif y == $h-1
        $maze[[x,y]].remove_wall(:right)
      else
        $rng.rand($ht) == 0 ? $maze[[x,y]].remove_wall(:down) : $maze[[x,y]].remove_wall(:right)
      end
    end
  end

  show_maze_small
  puts
  # show_maze_big
end


def randomized_prims_algorithm
  make_maze("Randomized Prim's Algorithm")

  wall_list = {}

  # Pick a cell, mark it as part of the maze. Add the walls of the cell to the wall list.
  cell = random_cell
  cell.in_maze = true
  cell.walls.each do |dir, wall|
    wall_list[wall] = true
  end

  # While there are walls in the list:
  while wall_list.length != 0
    # Pick a random wall from the list. 
    walls = wall_list.keys
    wall = walls[$rng.rand(walls.length)]
    next if $rng.rand($ht) != 0 && wall.vertical?
    length = wall.parents_in_maze.length

    # If the cell on the opposite side isn't in the maze yet: 
    $stdout.flush
    case wall.parents_in_maze.length
    when 2
      # If the cell on the opposite side already was in the maze, remove the wall from the list.
      wall_list.delete(wall)
    when 1
      parent_in_maze = wall.parents_in_maze[0]
      other_parent = wall.other_parent(parent_in_maze)
      if other_parent
      # Make the wall a passage if it leads to another cell
        wall.solid = false
      # mark the cell on the opposite side as part of the maze.
        other_parent.in_maze = true
      # Add the neighboring walls of the cell to the wall list.
        other_parent.walls.each do |dir, wall|
          wall_list[wall] = true
        end
      end
      wall_list.delete(wall)
    when 0
      puts "what the hell? This wall shouldn't be in the wall list!"
      puts "ur: #{wall.ur_parent}"
      puts "dl: #{wall.dl_parent}"
    end
  end
  show_maze_small
  puts
  show_maze_big
end

def depth_first
  make_maze("Depth First")

  # depth_first_recurse(random_cell)
  depth_first_stack

  show_maze_small
  puts
end

def depth_first_recurse(cell)
  cell.in_maze = true
  cell.neighbor_dirs.shuffle.each do |dir|
    neighbor = cell.get_adjacent(dir)
    unless neighbor.in_maze
      cell.remove_wall(dir)
      depth_first_recurse(neighbor)
    end
  end
end

def depth_first_stack

  stack = [random_cell]
  until stack.empty?
    cell = stack.last
    cell.in_maze = true
    neighbors = cell.neighbors_not_in_maze
    if neighbors.empty?
      stack = stack[0..-2]
    else
      neighbor = neighbors.shuffle.first
      next if $rng.rand($ht) != 0 && ![:left,:right].include?(cell.dir_to_neighbor(neighbor))
      cell.remove_wall(cell.dir_to_neighbor(neighbor))

      stack << neighbor 
    end
  end
end

binary_tree
randomized_prims_algorithm
depth_first

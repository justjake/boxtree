require 'bundler/setup'
require 'yoga_layout'
require 'logger'
require 'io/console'

LOGFILE = File.open('./development.log', 'a')
LOGGER = Logger.new(LOGFILE)

# Module Boxtree implements a basic scene graph based on the Yoga layout
# library, for rendering to monospaced text output, eg, the VT100 terminal.
#
# Current non goals:
# - color
# - sub-character rendering
# - efficiency
module Boxtree
  SOLID = '*'
  EMPTY = ' '

  def self.id
    @id ||= 0
    @id += 1
  end

  def self.draw_tree(root)
    root.calculate_layout
    array_2d = Array2D.new(root.layout[:width], root.layout[:height])

    each_node(root).each do |node|
      puts node.layout
      draw_node_to(node, array_2d)
    end

    array_2d
  end

  def self.children(yoga_node)
    Enumerator.new do |y|
      yoga_node.get_child_count.times do |i|
        y << yoga_node.get_child(i)
      end
    end
  end

  def self.each_node(yoga_node)
    Enumerator.new do |y|
      q = [yoga_node]
      while q.length > 0
        node = q.pop
        q.concat children(node).to_a
        y << node
      end
    end
  end

  def self.draw_node_to(yoga_node, array_2d)
    layout = yoga_node.layout
    slice = array_2d.slice(layout[:width], layout[:height], layout[:left], layout[:top])
    Text.new(string: "Item #{id}", node: yoga_node).draw_to(slice)
  end


  # The basic component in our system
  class View
    def initialize(node: nil)
      @node = node || YogaLayout::Node.new
    end

    attr_reader :node

    def draw_to(array_2d)
      array_2d.each do |x, y, _|
        calc = char_at(x, y)
        array_2d[x, y] = calc if calc
      end
    end

    def char_at(x, y)
      # borders
      top, right, bottom, left = layout_border
      if y <= (top - 1)
        return solid(x, y)
      end

      if y >= (layout_height - bottom)
        return solid(x, y)
      end

      if x <= (left - 1)
        return solid(x, y)
      end

      if x >= (layout_width - right)
        return solid(x, y)
      end

      nil
    end

    def solid(x, y)
      #puts "solid: #{x}, #{y}"
      SOLID
    end

    def to_array_2d
      array_2d = Array2D.new(layout[:width], layout[:height])
      draw_to(array_2d)
      array_2d
    end

    def layout
      node.layout
    end

    def layout_border
      [
        node.layout_get_border_top.to_i,
        node.layout_get_border_right.to_i,
        node.layout_get_border_bottom.to_i,
        node.layout_get_border_left.to_i,
      ]
    end

    def layout_padding
      [
        node.layout_get_padding_top.to_i,
        node.layout_get_padding_right.to_i,
        node.layout_get_padding_bottom.to_i,
        node.layout_get_padding_left.to_i,
      ]
    end

    def layout_inset
      layout_border.zip(layout_padding).map { |pair| pair.inject(&:+) }
    end

    def layout_width
      node.layout_get_width.to_i
    end

    def layout_height
      node.layout_get_height.to_i
    end

    def style
      node.style
    end

    def to_s
      to_array_2d.rows.map { |r| r.map { |x| x || EMPTY }.join }.join("\n")
    end
  end

  # Text lays out a string within its bounds.
  class Text < View
    def initialize(string: '', **rest)
      super(**rest)
      @string = string
      #node.set_measure_func(method(:measure_func))
    end

    def char_at(x, y)
      result = nil

      # Draw characters inside of the border and padding
      top, right, bottom, left = layout_inset
      if (x >= left && x < layout_width - right) &&
          (y >= top && y < layout_height - bottom)
        inner_x = x - left
        inner_y = y - top
        result = cached_array_2d[inner_x, inner_y]
        puts "drawing result char #{result} at #{x}, #{y}" if result
      end

      # Or, draw the regular stuff.
      result || super
    end

    attr_reader :string
    def string=(next_string)
      prev = @string
      @string = next_string
      return if prev == next_string

      @cached_array_2d = nil
      node.mark_dirty
    end

    # Yoga layout measurement function
    def measure_func(given_width, width_mode, given_height, height_mode)
      width = nil
      height = nil
      length = string.length.to_f
      height_given_width = (length / given_width).ceil

      # We just print whatever we got, yo
      case width_mode
      when :at_most
        if length < given_width
          width = length
          height = 1
        else
          height = height_given_width
        end
      when :exactly
        height = height_given_width
      when :undefined
        width = length
        height = 1
      end

      # Make sure height does not betray us....?
      case height_mode
      when :at_most
        height = [height, given_height].compact.max
      when :exactly
        height = given_height
      end

      if width_mode == :exactly
      end

      [width, height]
    end

    private

    def cached_array_2d
      return @cached_array_2d if @cached_array_2d

      top, right, bottom, left = layout_inset
      inner_width = (layout_width - left - right)
      inner_height = (layout_height - top - bottom)

      @cached_array_2d ||= Array2D.new(inner_width, inner_height, data: string.split(''))
    end
  end

  class Array2D
    def self.from_points(points)
      max_x, max_y, _ = points.last
      instance = new(max_x + 1, max_y + 1)
      points.each do |point|
        x, y, value = point
        instance[x, y] = value
      end
      instance
    end

    def initialize(width, height, origin_x: 0, origin_y: 0, backing: nil, data: nil)
      @width = width.to_i
      @height = height.to_i
      @origin_x = origin_x.to_i
      @origin_y = origin_y.to_i

      data_size = @width * @height

      if backing
        @backing = backing
        @data = nil
      elsif data
        @data = data
        @data.fill(nil, data.length, data_size - data.length)
        @backing = nil
      else
        @data = Array.new(@width * @height)
        @backing = nil
      end
    end

    attr_reader :width
    attr_reader :height
    attr_reader :origin_x
    attr_reader :origin_y

    def []=(x, y, char)
      idx = idx(x, y)
      data[idx] = char
    end

    def [](x, y)
      data[idx(x, y)]
    end

    def rows
      return dup.rows if @backing

      Array.new(height) do |i|
        first = idx(0, i)
        last = idx(width - 1, i)
        data[first..last]
      end
    end

    def inspect
      row_lines = rows.map(&:inspect).join("\n  ")
      <<-EOS
Array2D[
  #{row_lines}
]
      EOS
    end

    def to_s
      rows.map do |row|
        row.map do |nth_char|
          nth_char || EMPTY
        end.join
      end.join("\n")
    end

    def enum
      # reduce array allocations by one zillion
      result = Array.new(3)

      Enumerator.new do |emit|
        height.times do |y|
          width.times do |x|
            result[0] = x
            result[1] = y
            result[2] = self[x, y]
            emit << result
          end
        end
      end
    end

    def each
      return enum unless block_given?
      enum.each { |x, y, value| yield(x, y, value) }
    end

    # Highly inefficient
    def map
      val = self.class.new(width, height)
      enum.each do |x, y, value|
        value = yield(x, y, value)
        val[x, y] = value
      end
    end

    def dup
      map { |_, _, v| v }
    end

    def slice(width, height, origin_x, origin_y)
      self.class.new(
        width,
        height,
        origin_x: origin_x,
        origin_y: origin_y,
        backing: self
      )
    end

    def idx(x, y)
      if @backing
        @backing.idx(x + origin_x, y + origin_y)
      else
        x + y * width
      end
    end

    protected

    def data
      @data || @backing.data
    end
  end
end

require 'pry'

height, width = $stdout.winsize

layout = YogaLayout::Node[
  width: width,
  height: height,
  flex_direction: :row,
  padding: 3,
  border: 1,
  children: [
    YogaLayout::Node[
      width: 30,
      margin_end: 5,
      border: 1,
    ],
    YogaLayout::Node[
      height: 10,
      align_self: :center,
      flex_grow: 1,
      border: 1,
    ]
  ],
]

#layout = YogaLayout::Node[
  #width: 5,
  #height: 5,
  #border: 1,
#]

data = Boxtree.draw_tree(layout)
puts data

binding.pry

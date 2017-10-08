require 'boxtree/view'

module Boxtree
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
end

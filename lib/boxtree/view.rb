module Boxtree
  # The basic component in our system.
  # See {#draw_to} for the main interface.
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
        return SOLID
      end

      if y >= (layout_height - bottom)
        return SOLID
      end

      if x <= (left - 1)
        return SOLID
      end

      if x >= (layout_width - right)
        return SOLID
      end

      nil
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
end

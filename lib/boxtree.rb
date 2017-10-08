require 'yoga_layout'

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

  require 'boxtree/array2d'
  require 'boxtree/view'
  require 'boxtree/text'

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
end

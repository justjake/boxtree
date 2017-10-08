module Boxtree
  # A 2-D array, backed by a regular Ruby array. This data structure is used to
  # represent the output of rendering our views.
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

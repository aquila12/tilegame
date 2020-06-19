class TileMap
  class Segment
    SENTRY = { dirty: false, id: nil }

    def initialize(tiles_x, tiles_y, tile_w, tile_h, tileset)
      @w = tiles_x
      @h = tiles_y
      @tile_w = tile_w
      @tile_h = tile_h
      @tileset = tileset
      @tiles = (@w * @h).times.map { { dirty: true, id: nil } }
    end

    def tile(x, y)
      return SENTRY if x < 0 || x >= @w || y < 0 || y >= @h
      @tiles[@w * y + x]
    end

    def each_tile
      @h.times { |y| @w.times { |x| yield(tile(x,y),x,y) } }
    end

    def _renderable_tile(tile, x, y)
      tilesource = @tileset[tile[:id]]
      {
        x: (x * @tile_w), y: (y * @tile_h),
        w: @tile_w, h: @tile_h,
        path: tilesource[:path],
        source_x: tilesource[:x],
        source_y: tilesource[:y],
        source_w: @tile_w,
        source_h: @tile_h
      }
    end

    def _renderable_tiles
      list = []
      each_tile do |tile, x, y|
        next unless tile[:dirty]
        list << _renderable_tile(tile, x, y)
      end
      list
    end

    def load(data)
      each_tile do |tile, x, y|
        tile[:id] = data[y][x]
      end
    end

    def render(target)
      renderable = _renderable_tiles
      target.sprites << renderable unless renderable.empty?
    end
  end

  # Map segments - "square" loadable sections of map
  # Loader callback - to get unloaded sections
  # Keep 4 segments loaded (or N^2 segments)
  # On each update, adjust the camera, callback for any segments
  #  which need to be recycled
  # Update loaded segments in case they have any animated tiles

  def initialize(name, tile_w, tile_h, seg_size, &loader)
    @name = name
    @loader = loader
    @seg_size = seg_size
    @tile_w = tile_w
    @tile_h = tile_h
    @width = @seg_size * @tile_w
    @height = @seg_size * @tile_h
    @segments = []
    pan_abs(0, 0)
  end

  def pan_abs(x, y)
    @pan = {x: x, y: y}
  end

  def pan_rel(x, y)
    @pan[:x] += x
    @pan[:y] += y
  end

  def load_segment(sx, sy)
    name = "#{name}_#{sx.to_i}_#{sy.to_i}"
    segment_data = @loader.call(sx, sy)
    s = Segment.new(@seg_size, @seg_size, @tile_w, @tile_h, segment_data[:tileset])
    s.load(segment_data[:tilemap])
    @segments << {
      sx: sx, sy: sy, x: sx * @width, y: sy * @height, segment: s, name: name
    }
  end

  def render(args)
    @segments.each do |s|
      s[:segment].render(args.render_target(s[:name]))

      args.outputs.sprites << {
        x: s[:x] - @pan[:x], y: s[:y] - @pan[:y], w: @width, h: @height,
        path: s[:name], source_x: 0, source_y: 0, source_w: @width, source_h: @height
      }
    end
  end
end

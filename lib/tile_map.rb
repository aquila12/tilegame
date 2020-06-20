class TileMapSprite
  attr_sprite

  def initialize
    @r = 255
    @g = 255
    @b = 255
    @a = 255
  end

  def position(x, y)
    @x = x
    @y = y
  end

  def dimensions(w, h)
    @source_w = @w = w
    @source_h = @h = h
  end

  def source(path, x, y)
    @path = path
    @source_x = x
    @source_y = y
  end
end

class TileMap
  class TileSprite < TileMapSprite
    attr_accessor :animated

    def initialize
      super
    end

    def set(tiledef)
      @tiledef = tiledef
      @animated = tiledef[:animated]
      source(@tiledef[:path], @tiledef[:x], @tiledef[:y])
    end

    def animate
      @source_x = @tiledef[:x]
      @source_y = @tiledef[:y]
    end
  end

  # Map segments - "square" loadable sections of map
  # Loader callback - to get unloaded sections
  # Keep 4 segments loaded (or N^2 segments)
  # On each update, adjust the camera, callback for any segments
  #  which need to be recycled
  # Update loaded segments in case they have any animated tiles

  def initialize(name, tile_width, tile_height, seg_size, buffer_size, &loader)
    super
    @name = name
    @loader = loader
    @seg_size = seg_size
    @tile_width = tile_width
    @tile_height = tile_height
    @tile_origin_x = @tile_origin_y = 0
    @draw_tiles_x = (1280 / tile_width).floor + 1
    @draw_tiles_y = (720 / tile_height).floor + 1
    @tiles = Array.new(buffer_size * buffer_size, { path: :null, x: 0, y: 0 })
    @buffer_size = buffer_size
    init_tilesprites
    pan_abs(0, 0)
  end

  def init_tilesprites
    @tilesprites = (@draw_tiles_x * @draw_tiles_y).times.map do
      t = TileSprite.new
      t.dimensions(@tile_width, @tile_height)
      t
    end
  end

  def set_tile(x, y, v)
    @tiles[y * @buffer_size + x] = v
  end

  def origin(ox, oy)
    @ox = ox
    @oy = oy
  end

  def pan_abs(x, y)
    @pan = {x: x, y: y}
    update_draw_window
    maybe_load
  end

  def pan_rel(x, y)
    @pan[:x] += x
    @pan[:y] += y
    update_draw_window
    maybe_load
  end

  def load_segment(sx, sy)
    name = "#{@name}_#{sx.to_i}_#{sy.to_i}"
    segment_data = @loader.call(sx, sy)
    return false unless segment_data

    x0 = sx * @seg_size
    y0 = sy * @seg_size
    tilemap = segment_data[:tilemap]
    tileset = segment_data[:tileset]
    @seg_size.times do |x|
      @seg_size.times do |y|
        tile = tilemap[x][y]
        set_tile(x + x0, y + y0, tileset[tile])
      end
    end
  end

  def origin
    {
      x: @pan[:x] - @tile_origin_x,
      y: @pan[:y] - @tile_origin_y
    }
  end

  def update_draw_window
    o = origin
    @tx0, @x0 = o[:x].divmod(@tile_width)
    @ty0, @y0 = o[:y].divmod(@tile_height)
    @tx1 = @tx0 + @draw_tiles_x
    @ty1 = @ty0 + @draw_tiles_y
  end

  def maybe_load
    dx = dy = 0
    case
    when @tx0 < 1 then dx = @seg_size
    when @tx1 >= @buffer_size then dx = -@seg_size
    end

    case
    when @ty0 < 1 then dy = @seg_size
    when @ty1 >= @buffer_size then dy = -@seg_size
    end

    shuffle_tiles(dx, dy) unless dx==0 && dy==0
    # TODO: Boundary load
  end

  # TODO: Call this?
  def shuffle_tiles(dx, dy)
    @tile_origin_x -= dx * @tile_width
    @tile_origin_y -= dy * @tile_height
    @tiles.rotate!(- (dy * @buffer_size + dx))
    update_draw_window
  end

  def update_tile_sprites
    n = 0
    y = -@y0
    t = @ty0 * @buffer_size + @tx0
    (@ty0...@ty1).each do |ty|
      x = -@x0
      t0 = t
      (@tx0...@tx1).each do |tx|
        tile = @tiles[t] # NB: No bounds check
        @tilesprites[n].position(x, y)
        @tilesprites[n].source(tile[:path], tile[:x], tile[:y])
        n += 1
        t += 1
        x += @tile_width
      end
      t = t0 + @buffer_size
      y += @tile_height
    end
  end

  def render(args)
    update_tile_sprites
    args.outputs.sprites << @tilesprites
  end
end

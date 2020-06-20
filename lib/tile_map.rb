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

  def initialize(name, tile_width, tile_height, seg_size, n_segs, &loader)
    super
    @name = name
    @loader = loader
    @seg_size = seg_size
    @tile_width = tile_width
    @tile_height = tile_height
    @seg_count = n_segs
    @buffer_size = seg_size * n_segs
    @tile_origin_x = @tile_origin_y = @sox = @soy = 0
    @draw_tiles_x = (1280 / tile_width).floor + 1
    @draw_tiles_y = (720 / tile_height).floor + 1
    @tile_count = @buffer_size * @buffer_size
    @tiles = Array.new(@tile_count, { path: :null, x: 0, y: 0 })
    init_tilesprites
    pan_abs(0, 0)
    fill_buffer
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

  def fill_buffer
    @seg_count.times do |sy|
      @seg_count.times do |sx|
        load_segment(sx + @sox, sy + @soy)
      end
    end
  end

  def load_segment(sx, sy)
    segment_data = @loader.call(sx, sy)
    return false unless segment_data

    x0 = (sx - @sox) * @seg_size
    y0 = (sy - @soy) * @seg_size
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
    sdx = sdy = 0
    case
    when @tx0 < 1 then sdx = 1
    when @tx1 >= @buffer_size then sdx = -1
    end

    case
    when @ty0 < 1 then sdy = 1
    when @ty1 >= @buffer_size then sdy = -1
    end

    return if sdx==0 && sdy==0

    shuffle_tiles(sdx, sdy)
    load_boundary(sdx, sdy)
  end

  def load_boundary(sdx, sdy)
    lbx = sdx > 0 ? @sox : (@seg_count + @sox - 1)
    lby = sdy > 0 ? @soy : (@seg_count + @soy - 1)
    x_loads = sdx == 0 ? [] : @seg_count.times.map { |ly| { x: lbx, y: @soy + ly } }
    y_loads = sdy == 0 ? [] : @seg_count.times.map { |lx| { x: @sox + lx, y: lby } }
    loads = x_loads | y_loads
    loads.each { |l| load_segment(l[:x], l[:y]) }
  end

  def shuffle_tiles(sdx, sdy)
    @sox -= sdx
    @soy -= sdy
    dx, dy = [sdx, sdy].map { |n| n * @seg_size }
    @tile_origin_x -= dx * @tile_width
    @tile_origin_y -= dy * @tile_height
    @tiles.rotate!(- (dy * @buffer_size + dx))
    update_draw_window
  end

  def get(tile)
    @tiles[tile]
  end

  def update_tile_sprites
    n = 0
    y = -@y0
    t = @ty0 * @buffer_size + @tx0
    @draw_tiles_y.times do
      x = -@x0
      t0 = t
      @draw_tiles_x.times do
        tile = @tiles[t]
        @tilesprites[n].position(x, y)
        @tilesprites[n].source(tile[:path], tile[:x], tile[:y])
        n += 1
        t += 1
        x += @tile_width
      end
      t = (t0 + @buffer_size).to_i
      y += @tile_height
    end
  end

  def render(args)
    update_tile_sprites
    args.outputs.labels << [0, 60, "Current origin: #{@tile_origin_x}, #{@tile_origin_y}"]
    args.outputs.sprites << @tilesprites
  end
end

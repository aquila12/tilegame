class TileSet
  def initialize(definition)
    w = definition[:tile_width]
    h = definition[:tile_height]
    @tiles = definition[:tiles].transform_values do |frame_array|
      frames = frame_array.map { |p| [p[0] * w, p[1] * h].map(&:to_i) }
      {
        path: definition[:path],
        animated: frames.count > 1,
        frames: frames,
        current_frame: 0,
        x: frames.first[0],
        y: frames.first[1],
        w: w,
        h: h
      }
    end
    @delay = @animate_delay = definition[:animate_delay]
  end

  def [](tile_id)
    @tiles.fetch(tile_id)
  end

  def _animate_tiles
    @tiles.each do |_id, t|
      next unless t[:animated]
      n = t[:current_frame] + 1
      n = 0 if n >= t[:frames].count
      frame = t[:frames][n]
      t[:x] = frame[0]
      t[:y] = frame[1]
      t[:current_frame] = n
    end
  end

  def animate
    @delay -= 1
    if @delay <= 0
      @delay = @animate_delay
      _animate_tiles
    end
  end
end

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
    @w = w
    @h = h
  end

  def source(path, x, y, w, h)
    # FIXME: with render_targets this works with source_*
    @path = path
    @tile_x = x
    @tile_y = y
    @tile_w = w
    @tile_h = h
  end

  def _region(x,y,w,h)
    "(#{w}×#{h})@(#{x},#{y})"
  end

  def to_s
    s = _region(@source_x,@source_y,@tile_w,@tile_h)
    d = _region(@x,@y,@w,@h)
    t = "#%02x%02x%02x, %d" % [@r,@g,@b,@a]
    "#{path} #{s}-(#{t})->#{d}"
  end
end

class TileMap
  # Tile dimensions are *drawn* dimensions
  # Map segment is a logically-square loadable section of map
  # Keeps n_segs×n_segs segments in the buffer (MUST be bigger than viewport!)
  #
  # Loader block responds to load(seg_x, seg_y) and returns:
  # {
  #   tilemap: array of arrays of tile_id (dereferenced as [row][col])
  #   tileset: collection of tiles dereferenced by [tile_id]
  # }
  # - tiles must have the keys :path, :x, :y, :w, :h describing the image source
  def initialize(tile_width, tile_height, seg_size, n_segs, &loader)
    @loader = loader
    @seg_size = seg_size
    @tile_width = tile_width
    @tile_height = tile_height
    @seg_count = n_segs
    @buffer_size = seg_size * n_segs
    @tile_origin_x = @tile_origin_y = @sox = @soy = 0
    @draw_tiles_x = (1280 / tile_width).ceil + 1
    @draw_tiles_y = (720 / tile_height).ceil + 1
    draw_limit = @buffer_size - @seg_size
    raise RuntimeError, "Buffer is too small" if @draw_tiles_x > draw_limit || @draw_tiles_y > draw_limit

    @tile_count = @buffer_size * @buffer_size
    @tiles = Array.new(@tile_count, { path: :null, x: 0, y: 0 })
    init_tilesprites
    pan_abs(0, 0)
    fill_buffer
  end

  def init_tilesprites
    @tilesprites = (@draw_tiles_x * @draw_tiles_y).times.map do
      t = TileMapSprite.new
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
    @seg_size.times do |row|
      @seg_size.times do |col|
        tile = tilemap[row][col]
        set_tile(col + x0, row + y0, tileset[tile])
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
        sprite = @tilesprites[n]
        sprite.position(x, y)
        sprite.source(tile[:path], tile[:x], tile[:y], tile[:w], tile[:h])
        n += 1
        t += 1
        x += @tile_width
      end
      t = (t0 + @buffer_size).to_i
      y += @tile_height
    end
  end

  def static_render(target)
    target.static_sprites << @tilesprites
    @static = true
  end

  def render(target)
    update_tile_sprites
    target.labels << [0, 60, "Current origin: #{@tile_origin_x}, #{@tile_origin_y}"]
    target.sprites << @tilesprites unless @static
  end
end

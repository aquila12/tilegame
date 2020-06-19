def derp(sprite)
  {
    x: sprite.x,
    y: sprite.y,
    w: sprite.w,
    h: sprite.h,
    path: sprite.path,
    source_x: sprite.source_x,
    source_y: sprite.source_y,
    source_w: sprite.source_w,
    source_h: sprite.source_h
  }
end

def vars(o)
  h = {}
  o.instance_variables.each do |v|
    h[v] = o.instance_variable_get(v)
  end
  h
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
  class Segment < TileMapSprite
    class TileSprite < TileMapSprite
      attr_accessor :dirty, :animated

      def initialize
        super
        @dirty = true
      end

      def set(tiledef)
        @dirty = true
        @tiledef = tiledef
        @animated = tiledef[:animated]
        source(@tiledef[:path], @tiledef[:x], @tiledef[:y])
      end

      def animate
        @source_x = @tiledef[:x]
        @source_y = @tiledef[:y]
      end
    end

    SENTRY = TileSprite.new

    attr_reader :ox, :oy

    def initialize(tiles_x, tiles_y, tile_width, tile_height, tileset)
      @tiles_x = tiles_x
      @tiles_y = tiles_y
      @tile_width = tile_width
      @tile_height = tile_height
      @tileset = tileset
      init_tileset
    end

    def init_tileset
      @tiles = (@tiles_x * @tiles_y).times.map { TileSprite.new }
      each_tile do |tile, x, y|
        tile.position(x * @tile_width, y * @tile_height)
        tile.dimensions(@tile_width, @tile_height)
      end
    end

    def origin(ox, oy)
      @ox = ox
      @oy = oy
    end

    def tile(x, y)
      return SENTRY if x < 0 || x >= @tiles_x || y < 0 || y >= @tiles_h
      @tiles[@tiles_x * y + x]
    end

    def each_tile
      @tiles_y.times { |y| @tiles_x.times { |x| yield(tile(x,y),x,y) } }
    end

    def dequeue_renderable!
      list = @tiles.find_all(&:dirty)
      list.each { |t| t.animated ? t.animate : t.dirty=false }
      list
    end

    def load(data)
      each_tile do |tile, x, y|
        id = data[y][x]
        tile.set(@tileset[id])
      end
    end
  end

  # Map segments - "square" loadable sections of map
  # Loader callback - to get unloaded sections
  # Keep 4 segments loaded (or N^2 segments)
  # On each update, adjust the camera, callback for any segments
  #  which need to be recycled
  # Update loaded segments in case they have any animated tiles

  def initialize(name, tile_width, tile_height, seg_size, &loader)
    super
    @name = name
    @loader = loader
    @seg_size = seg_size
    @tile_width = tile_width
    @tile_height = tile_height
    @width = @seg_size * @tile_width
    @height = @seg_size * @tile_height
    raise ArgumentError, "Map segment too big: #{@width}×#{@height}" if @width > 1280 || @height > 720
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
    name = "#{@name}_#{sx.to_i}_#{sy.to_i}"
    segment_data = @loader.call(sx, sy)
    s = Segment.new(@seg_size, @seg_size, @tile_width, @tile_height, segment_data[:tileset])

    s.origin(sx * @width, sy * @height)
    s.dimensions(@width, @height)
    s.source(name, 0, 0)

    s.load(segment_data[:tilemap])
    @segments << s
  end

  def _copy_spec(path)
    {
      x: 0, y: 0, w: @width, h: @height,
      path: path, source_x: 0, source_y: 0, source_w: @width, source_h: @height
    }
  end

  def render(args)
    @segments.each do |s|
      renderable = s.dequeue_renderable!
      unless renderable.empty?
        args.render_target(:seg_scratch).sprites << _copy_spec(s.path)
        args.render_target(s.path).sprites << _copy_spec(:seg_scratch)
        args.render_target(s.path).sprites << renderable
      end

      s.position(s.ox - @pan[:x], s.oy - @pan[:y])
    end

    args.outputs.sprites << @segments
  end
end

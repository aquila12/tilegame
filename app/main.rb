require 'lib/fps_profiler.rb'
require 'lib/tile_map.rb'
require 'lib/test_map.rb'

class Game
  @game

  def initialize(args)
    @args = args
    @tilemap = TileMap.new(:ground, TILE_W, TILE_H, SEGMENT_SIZE) { |x, y| segment(x,y) }
    36.times { |n| @tilemap.load_segment(*(n.divmod 6)) }

    update_solid_tile(0, 0, 32, 32, 160) # Water
    update_solid_tile(0, 1, 240, 240, 120) # Sand
    update_solid_tile(1, 0, 32, 192, 32) # Grass
    update_solid_tile(1, 1, 60, 60, 60) # Rock
    @cam = [0, 0]
  end

  def update_solid_tile(x, y, r, g, b)
    @args.render_target(:active_tileset).solids << {
      x: x * TILE_W, y: y * TILE_H, w: TILE_W, h: TILE_H,
      r: r, g: g, b: b, a: 255
    }
  end

  def tick
    inputs
    #update
    render
  end

  EXTENT = [1280, 720]
  MARGIN = 80
  PAN_RATE = 10
  def inputs
    pos = @args.inputs.mouse.position
    pan = 2.times.map { |dim|
      case
      when pos[dim] < MARGIN then -PAN_RATE
      when pos[dim] >= EXTENT[dim] - MARGIN then PAN_RATE
      else 0
      end
    }
    @tilemap.pan_rel(*pan)
  end

  def render
    @tilemap.render(@args)
  end
end

def tick(args)
  $game = @game = Game.new(args) if args.tick_count == 0
  @game.tick
  FpsProfiler.tick
  args.outputs.labels << { x: 8, y: 720 - 8, text: FpsProfiler.report }
  # args.outputs.labels << { x: 8, y: 720 - 28, text: args.outputs.static_sprites.count }
  #args.outputs.labels << { x: 8, y: 720 - 48, text: args.render_target(@name).static_sprites.count }
end

require 'lib/profiler.rb'
require 'lib/tile_map.rb'
require 'lib/test_map.rb'

class Game
  @game

  def initialize(args)
    @args = args
    @tileset = TileSet.new(TEST_TILE_DEFINITION)
    @tilemap = TileMap.new(:ground, TILE_W, TILE_H, SEGMENT_SIZE, 10) { |x, y| segment(x,y,@tileset) }
    @cam = [0, 0]
  end

  def tick
    inputs

    @tileset.animate
    @tilemap.render(@args.outputs)
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
end

def tick(args)
  $game = @game = Game.new(args) if args.tick_count == 0
  @fps_profiler ||= Profiler.new("FPS", 600)
  @tick_profiler ||= Profiler.new("Game tick", 600)
  @fps_profiler.profile_between_calls

  @tick_profiler.profile { @game.tick }
  args.outputs.labels << { x: 8, y: 720 - 8, text: @fps_profiler.report }
  args.outputs.labels << { x: 8, y: 720 - 28, text: @tick_profiler.report }
  args.outputs.labels << { x: 8, y: 720 - 48, text: Profiler.metaprofiler.report }
  # args.outputs.labels << { x: 8, y: 720 - 28, text: args.outputs.static_sprites.count }
  #args.outputs.labels << { x: 8, y: 720 - 48, text: args.render_target(@name).static_sprites.count }
end

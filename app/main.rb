require 'lib/fps_profiler.rb'
require 'lib/tile_map.rb'

TILE_W = 80
TILE_H = 40

MAP = [
  '................',
  '.gg......,,.....',
  '.gg......,,.....',
  '.gg......,,.....',
  '.gg......,,.....',
  '.gg..ll.........',
  '.gg..ll.........',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll.........',
  '.gg..ll.........',
  '................',
  '................',
  '................'
]

TILESET = {
  '.' => { path: :active_tileset, x: TILE_W, y: 0 },
  'g' => { path: :active_tileset, x: 0, y: TILE_H },
  'l' => { path: :active_tileset, x: TILE_W, y: TILE_H },
  ',' => { path: :active_tileset, x: 2*TILE_W, y: TILE_H, animated: 1 }
}

SEGMENT_DATA = { tilemap: MAP, tileset: TILESET }

class Game
  @game

  def initialize(args)
    @args = args
    @tilemap = TileMap.new(:ground, TILE_W, TILE_H, 16) { SEGMENT_DATA }
    @tilemap.load_segment(0, 0)
    @tilemap.load_segment(1, 1)
    update_solid_tile(0, 0, 32, 32, 32)
    update_solid_tile(1, 0, 32, 32, 128)
    update_solid_tile(0, 1, 32, 192, 32)
    update_solid_tile(1, 1, 255, 128, 64)
    update_solid_tile(2, 1, 32, 32, 96)
    update_solid_tile(3, 1, 32, 32, 128)
    update_solid_tile(4, 1, 32, 32, 160)
    update_solid_tile(5, 1, 32, 32, 128)
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
    TILESET[','][:x] = (2 + (@args.tick_count/30).floor % 4)*TILE_W
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

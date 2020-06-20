TILE_W = 80
TILE_H = 40

SEGMENT_SIZE = 5

SEGMENT_MAP = [
  'mhpbo',
  'hpboo',
  'pbooo',
  'booio',
  'ooooo'
]

ISLAND_SEGMENT = [
  'wssww',
  'sggss',
  'wssgs',
  'wwsgr',
  'rwwrw'
]

def diagonal_segment(top_left_tile, bottom_right_tile)
  5.times.map { |n|
    top_left_tile * (5-n) + bottom_right_tile * n
  }
end

def segment(sx,sy)
  row = SEGMENT_MAP[sy] || []
  segment_type = row[sx] || 'o'

  data = case segment_type
  when 'i' then ISLAND_SEGMENT
  else
    tl = {'m' => 'r', 'h' => 'g', 'p' => 'g', 'b' => 's', 'o' => 'w' }[segment_type]
    br = {'m' => 'g', 'h' => 'g', 'p' => 's', 'b' => 'w', 'o' => 'w' }[segment_type]
    diagonal_segment(tl, br)
  end

  { tilemap: data, tileset: TILESET }
end

MAP = [
  '................',
  '.gg......,,,,,,,',
  '.gg......,,,,,,,',
  '.gg......,,,,,,,',
  '.gg......,,,,,,,',
  '.gg..ll.........',
  '.gg..ll.........',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll..,,..gg.',
  '.gg..ll.........',
  '.gg..ll.........',
  '....,,,,,,,,,,,,',
  '....,,,,,,,,,,,,',
  '....,,,,,,,,,,,,'
]

TILESET = {
  'w' => { path: :active_tileset, x: 0, y: 0 },
  's' => { path: :active_tileset, x: 0, y: TILE_H },
  'g' => { path: :active_tileset, x: TILE_W, y: 0 },
  'r' => { path: :active_tileset, x: TILE_W, y: TILE_H }
}

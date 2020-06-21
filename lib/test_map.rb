TILE_W = 64
TILE_H = 36

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

def segment(sx, sy, tileset)
  row = SEGMENT_MAP[sy] || []
  segment_type = row[sx]
  segment_type = (rand < 0.05 ? 'i' : 'o') unless segment_type
  #puts "Load #{sx}, #{sy} => #{segment_type}"

  data = case segment_type
  when 'i' then ISLAND_SEGMENT
  else
    tl = {'m' => 'r', 'h' => 'g', 'p' => 'g', 'b' => 's', 'o' => 'w' }[segment_type]
    br = {'m' => 'g', 'h' => 'g', 'p' => 's', 'b' => 'w', 'o' => 'w' }[segment_type]
    diagonal_segment(tl, br)
  end

  { tilemap: data, tileset: tileset }
end

TEST_TILE_DEFINITION = {
  path: 'sprites/test-tiles.png',
  tile_width: 32,
  tile_height: 18,
  animate_delay: 5,
  tiles: {
    'w' => [[0,0],[0,1],[0,2],[0,3],[0,4],[0,5]],
    'g' => [[1,0]],
    's' => [[1,1]],
    'r' => [[1,2]],
    ' ' => [[1,3]]
  }
}

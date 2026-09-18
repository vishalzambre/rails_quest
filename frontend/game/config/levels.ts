export type PlatformSpec = { x: number; y: number; w: number; kind?: "ground" | "platform" }
export type PickupSpec = { x: number; y: number; type: "ruby" | "rails" | "boost" | "special" }
export type EnemySpec = { x: number; y: number; type: "bug" | "prod-bug" | "debt"; minX: number; maxX: number; speed: number }

export type LevelSpec = {
  key: string
  name: string
  width: number
  spawnX: number
  spawnY: number
  goalX: number
  platforms: PlatformSpec[]
  pickups: PickupSpec[]
  enemies: EnemySpec[]
}

const ground = (from: number, to: number, y = 500): PlatformSpec[] => {
  const tiles: PlatformSpec[] = []
  for (let x = from; x < to; x += 64) {
    tiles.push({ x, y, w: 64, kind: "ground" })
  }
  return tiles
}

const scatterRubies = (xs: number[], y: number): PickupSpec[] => xs.map((x) => ({ x, y, type: "ruby" as const }))

export const rubyValley = (): LevelSpec => {
  const platforms: PlatformSpec[] = [
    ...ground(0, 720),
    { x: 860, y: 430, w: 160, kind: "platform" },
    { x: 1080, y: 360, w: 140, kind: "platform" },
    ...ground(1280, 1880),
    { x: 1980, y: 420, w: 180, kind: "platform" },
    { x: 2240, y: 340, w: 160, kind: "platform" },
    { x: 2480, y: 280, w: 120, kind: "platform" },
    ...ground(2680, 3360),
    { x: 3480, y: 400, w: 150, kind: "platform" },
    { x: 3680, y: 330, w: 150, kind: "platform" },
    ...ground(3880, 4560)
  ]

  const pickups: PickupSpec[] = [
    ...scatterRubies([120, 200, 280, 420, 560], 458),
    ...scatterRubies([900, 980, 1120], 330),
    ...scatterRubies([1400, 1520, 1640, 1760], 458),
    ...scatterRubies([2020, 2100], 380),
    ...scatterRubies([2280, 2520], 250),
    ...scatterRubies([2760, 2900, 3040], 458),
    ...scatterRubies([3520, 3720], 300),
    ...scatterRubies([4000, 4120], 458),
    { x: 1100, y: 300, type: "rails" },
    { x: 1700, y: 430, type: "rails" },
    { x: 2300, y: 280, type: "rails" },
    { x: 3100, y: 430, type: "rails" },
    { x: 3500, y: 340, type: "rails" },
    { x: 2260, y: 280, type: "boost" },
    { x: 3700, y: 270, type: "boost" },
    { x: 2480, y: 220, type: "special" }
  ]

  const enemies: EnemySpec[] = [
    { x: 480, y: 460, type: "bug", minX: 400, maxX: 680, speed: 70 },
    { x: 1480, y: 460, type: "bug", minX: 1320, maxX: 1800, speed: 80 },
    { x: 1600, y: 460, type: "debt", minX: 1500, maxX: 1750, speed: 40 },
    { x: 2060, y: 380, type: "bug", minX: 1980, maxX: 2140, speed: 60 },
    { x: 3000, y: 460, type: "prod-bug", minX: 2720, maxX: 3280, speed: 110 },
    { x: 4100, y: 460, type: "bug", minX: 3920, maxX: 4400, speed: 90 }
  ]

  return {
    key: "ruby_valley",
    name: "Ruby Valley",
    width: 4560,
    spawnX: 80,
    spawnY: 360,
    goalX: 4420,
    platforms,
    pickups,
    enemies
  }
}

export const LEVELS: Record<string, () => LevelSpec> = {
  ruby_valley: rubyValley,
  rails_city: rubyValley,
  database_dungeon: rubyValley,
  production_mountain: rubyValley,
  production_boss: rubyValley
}

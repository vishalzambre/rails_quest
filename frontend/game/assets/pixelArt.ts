import Phaser from "phaser"

type PixelMap = string[]

const PALETTE: Record<string, string> = {
  ".": "#00000000",
  "n": "#070b1a",
  "b": "#1b243b",
  "w": "#f4e8c1",
  "r": "#cc342d",
  "d": "#8b1e1a",
  "o": "#ff8a3d",
  "g": "#3ddc97",
  "p": "#7c5cff",
  "k": "#3a2a1a",
  "t": "#8b5a2b",
  "y": "#f0c14a",
  "s": "#6b7280",
  "c": "#4cc9f0"
}

const paint = (scene: Phaser.Scene, key: string, pixels: PixelMap, scale = 4) => {
  const width = pixels[0].length
  const height = pixels.length
  const canvas = scene.textures.createCanvas(key, width * scale, height * scale)
  if (!canvas) return
  const ctx = canvas.getContext()
  pixels.forEach((row, y) => {
    ;[...row].forEach((cell, x) => {
      ctx.fillStyle = PALETTE[cell] || "#000"
      ctx.fillRect(x * scale, y * scale, scale, scale)
    })
  })
  canvas.refresh()
}

export const createPixelTextures = (scene: Phaser.Scene) => {
  paint(scene, "player", [
    "..rrrr..",
    ".rwwwwr.",
    ".rwbwbwr",
    ".rwwwwr.",
    "..rrrr..",
    ".brrrrb.",
    "b.rrrr.b",
    "..g..g..",
    "..g..g..",
    "..k..k.."
  ])

  paint(scene, "ruby", [
    "..r..",
    ".rrr.",
    "rrrrr",
    ".rrr.",
    "..r.."
  ], 3)

  paint(scene, "rails", [
    "ttttttt",
    "y.y.y.y",
    "ttttttt"
  ], 3)

  paint(scene, "boost", [
    "..g..",
    ".ggg.",
    "ggggg",
    ".g.g.",
    "g...g"
  ], 3)

  paint(scene, "special", [
    "..p..",
    ".prp.",
    "prrrp",
    ".prp.",
    "..p.."
  ], 4)

  paint(scene, "bug", [
    ".g.g.",
    "ggggg",
    "gngng",
    "ggggg",
    ".g.g."
  ], 3)

  paint(scene, "prod-bug", [
    ".r.r.",
    "rrrrr",
    "rwrwr",
    "rrrrr",
    "r...r"
  ], 3)

  paint(scene, "debt", [
    ".sss.",
    "sssss",
    "s.s.s",
    "sssss"
  ], 4)

  paint(scene, "ground", [
    "tttttttt",
    "kkkkkkkk",
    "bbbbbbbb"
  ], 8)

  paint(scene, "platform", [
    "oooooooo",
    "tttttttt"
  ], 6)

  paint(scene, "flag", [
    "g....",
    "gggg.",
    "g.gg.",
    "g....",
    "g....",
    "g...."
  ], 5)

  const bg = scene.textures.createCanvas("sky", 64, 64)
  if (bg) {
    const ctx = bg.getContext()
    ctx.fillStyle = "#10182d"
    ctx.fillRect(0, 0, 64, 64)
    ctx.fillStyle = "#f4e8c1"
    ctx.fillRect(8, 10, 2, 2)
    ctx.fillRect(40, 22, 2, 2)
    ctx.fillRect(22, 48, 2, 2)
    bg.refresh()
  }
}

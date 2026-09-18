import Phaser from "phaser"
import { createPixelTextures } from "../assets/pixelArt"

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene")
  }

  create() {
    createPixelTextures(this)
    this.scene.start("GameScene")
  }
}

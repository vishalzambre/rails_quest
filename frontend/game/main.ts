import Phaser from "phaser"
import { BootScene } from "./scenes/BootScene"
import { GameScene } from "./scenes/GameScene"
import { PreloadScene } from "./scenes/PreloadScene"
import { QuestionScene } from "./scenes/QuestionScene"
import type { GameBootstrap } from "./types"
import { GAME_HEIGHT, GAME_WIDTH } from "./types"

export const createGame = (parent: HTMLElement, bootstrap: GameBootstrap) => {
  const fullscreenTarget = parent.closest("#rails-runner") instanceof HTMLElement
    ? parent.closest("#rails-runner") as HTMLElement
    : parent

  const game = new Phaser.Game({
    type: Phaser.AUTO,
    parent,
    backgroundColor: "#10182d",
    pixelArt: true,
    antialias: false,
    roundPixels: true,
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH,
      width: GAME_WIDTH,
      height: GAME_HEIGHT,
      fullscreenTarget,
      expandParent: false
    },
    physics: {
      default: "arcade",
      arcade: {
        gravity: { x: 0, y: 1100 },
        debug: false
      }
    },
    scene: [BootScene, PreloadScene, GameScene, QuestionScene],
    audio: { disableWebAudio: false },
    input: { activePointers: 3 }
  })
  game.registry.set("bootstrap", bootstrap)
  return game
}

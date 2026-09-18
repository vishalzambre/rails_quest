export class InputSystem {
  left = false
  right = false
  jump = false
  private jumpConsumed = false

  attach(scene: Phaser.Scene) {
    const kb = scene.input.keyboard
    const left = kb?.addKey("LEFT")
    const right = kb?.addKey("RIGHT")
    const up = kb?.addKey("UP")
    const space = kb?.addKey("SPACE")
    const a = kb?.addKey("A")
    const d = kb?.addKey("D")

    const onControl = (event: Event) => {
      const { key, down } = (event as CustomEvent<{ key: string; down: boolean }>).detail
      if (key === "left") this.left = down
      if (key === "right") this.right = down
      if (key === "jump") this.jump = down
    }
    window.addEventListener("runner-control", onControl)
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      window.removeEventListener("runner-control", onControl)
    })

    scene.events.on("update", () => {
      this.left = !!(left?.isDown || a?.isDown || this.touchLeft)
      this.right = !!(right?.isDown || d?.isDown || this.touchRight)
      this.jump = !!(up?.isDown || space?.isDown || this.touchJump)
    })
  }

  private touchLeft = false
  private touchRight = false
  private touchJump = false

  bindWindow() {
    const onControl = (event: Event) => {
      const { key, down } = (event as CustomEvent<{ key: string; down: boolean }>).detail
      if (key === "left") this.touchLeft = down
      if (key === "right") this.touchRight = down
      if (key === "jump") this.touchJump = down
    }
    window.addEventListener("runner-control", onControl)
  }

  consumeJump(): boolean {
    if (this.jump && !this.jumpConsumed) {
      this.jumpConsumed = true
      return true
    }
    if (!this.jump) this.jumpConsumed = false
    return false
  }
}

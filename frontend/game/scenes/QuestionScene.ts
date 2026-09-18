import Phaser from "phaser"
import type { QuestionPayload } from "../types"

export class QuestionScene extends Phaser.Scene {
  constructor() {
    super("QuestionScene")
  }

  create(data: {
    question: QuestionPayload
    onAnswer: (key: string) => Promise<{ correct: boolean; points_awarded: number }>
    onDone: () => void
  }) {
    const { width, height } = this.scale
    this.add.rectangle(0, 0, width, height, 0x070b1a, 0.82).setOrigin(0)
    this.add.text(width / 2, 48, `${data.question.category} · ${data.question.difficulty}`, {
      fontFamily: '"Press Start 2P", monospace',
      fontSize: "10px",
      color: "#ff8a3d"
    }).setOrigin(0.5)

    this.add.text(width / 2, 96, data.question.prompt, {
      fontFamily: '"IBM Plex Sans", sans-serif',
      fontSize: "20px",
      color: "#f4e8c1",
      wordWrap: { width: width - 80 },
      align: "center"
    }).setOrigin(0.5, 0)

    data.question.choices.forEach((choice, index) => {
      const y = 200 + index * 68
      const box = this.add.rectangle(width / 2, y, width - 80, 56, 0x172038).setStrokeStyle(3, 0x000000).setInteractive({ useHandCursor: true })
      const label = this.add.text(width / 2, y, `${choice.key}. ${choice.text}`, {
        fontFamily: '"IBM Plex Sans", sans-serif',
        fontSize: "16px",
        color: "#f4e8c1",
        wordWrap: { width: width - 120 }
      }).setOrigin(0.5)

      box.on("pointerup", async () => {
        box.disableInteractive()
        const result = await data.onAnswer(choice.key)
        box.setFillStyle(result.correct ? 0x14332a : 0x3a1515)
        label.setText(result.correct ? "CORRECT +points" : "WRONG")
        this.time.delayedCall(900, () => data.onDone())
      })
    })
  }
}

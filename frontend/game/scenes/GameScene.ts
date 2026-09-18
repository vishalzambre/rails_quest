import Phaser from "phaser"
import { GameApi } from "../api/Client"
import { LEVELS } from "../config/levels"
import { AudioSystem } from "../systems/AudioSystem"
import { GameEventSystem } from "../systems/GameEventSystem"
import { previewDelta } from "../systems/ScorePreview"
import type { GameBootstrap, GameState } from "../types"
import { GAME_HEIGHT, GAME_WIDTH } from "../types"

export class GameScene extends Phaser.Scene {
  private api!: GameApi
  private bootstrap!: GameBootstrap
  private audio = new AudioSystem()
  private eventsQueue!: GameEventSystem
  private state: GameState = "START"
  private score = 0
  private lives = 3
  private remaining = 90
  private questionsAsked = 0
  private questionsCorrect = 0
  private gems = 0
  private player!: Phaser.Types.Physics.Arcade.SpriteWithDynamicBody
  private platforms!: Phaser.Physics.Arcade.StaticGroup
  private pickups!: Phaser.Physics.Arcade.Group
  private foes!: Phaser.Physics.Arcade.Group
  private hud!: Phaser.GameObjects.Text
  private banner!: Phaser.GameObjects.Text
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys
  private wasd!: Record<string, Phaser.Input.Keyboard.Key>
  private touch = { left: false, right: false, jump: false }
  private invulnerableUntil = 0
  private nextQuestionAt = 0
  private slowUntil = 0
  private startedAt = 0
  private spawn = { x: 80, y: 360 }
  private goalX = 4400
  private finishing = false
  private coyote = 0

  constructor() {
    super("GameScene")
  }

  init() {
    this.bootstrap = this.registry.get("bootstrap")
    this.api = new GameApi(this.bootstrap)
    this.eventsQueue = new GameEventSystem(this.api)
    this.lives = this.bootstrap.config.lives
    this.remaining = this.bootstrap.config.duration_seconds
  }

  create() {
    const level = (LEVELS[this.bootstrap.levelKey] || LEVELS.ruby_valley)()
    this.spawn = { x: level.spawnX, y: level.spawnY }
    this.goalX = level.goalX
    this.physics.world.setBounds(0, 0, level.width, GAME_HEIGHT)
    this.cameras.main.setBounds(0, 0, level.width, GAME_HEIGHT)
    this.cameras.main.setBackgroundColor("#10182d")
    this.add.tileSprite(0, 0, level.width, GAME_HEIGHT, "sky").setOrigin(0).setScrollFactor(0.15)

    this.platforms = this.physics.add.staticGroup()
    level.platforms.forEach((spec) => {
      const tile = this.platforms.create(spec.x + spec.w / 2, spec.y, spec.kind === "ground" ? "ground" : "platform") as Phaser.Physics.Arcade.Sprite
      tile.setDisplaySize(spec.w, spec.kind === "ground" ? 40 : 24).refreshBody()
    })

    this.pickups = this.physics.add.group({ allowGravity: false })
    level.pickups.forEach((item) => {
      const sprite = this.pickups.create(item.x, item.y, item.type === "ruby" ? "ruby" : item.type === "rails" ? "rails" : item.type === "boost" ? "boost" : "special") as Phaser.Physics.Arcade.Sprite
      sprite.setData("kind", item.type)
      sprite.setBounceY(0.2)
    })

    this.foes = this.physics.add.group()
    level.enemies.forEach((enemy) => {
      const sprite = this.foes.create(enemy.x, enemy.y, enemy.type) as Phaser.Physics.Arcade.Sprite
      sprite.setData("spec", enemy)
      sprite.setVelocityX(enemy.speed)
      sprite.setCollideWorldBounds(true)
      sprite.setBounce(0)
    })

    this.player = this.physics.add.sprite(this.spawn.x, this.spawn.y, "player")
    this.player.setCollideWorldBounds(true)
    this.player.setMaxVelocity(280, 900)
    this.player.setDragX(1400)
    this.cameras.main.startFollow(this.player, true, 0.12, 0.12)
    this.add.image(this.goalX, 430, "flag")

    this.physics.add.collider(this.player, this.platforms)
    this.physics.add.collider(this.foes, this.platforms)
    this.physics.add.overlap(this.player, this.pickups, this.collect, undefined, this)
    this.physics.add.overlap(this.player, this.foes, this.hitFoe, undefined, this)

    this.cursors = this.input.keyboard!.createCursorKeys()
    this.wasd = this.input.keyboard!.addKeys("W,A,S,D,SPACE") as Record<string, Phaser.Input.Keyboard.Key>
    const onControl = (event: Event) => {
      const { key, down } = (event as CustomEvent<{ key: string; down: boolean }>).detail
      if (key === "left") this.touch.left = down
      if (key === "right") this.touch.right = down
      if (key === "jump") this.touch.jump = down
    }
    window.addEventListener("runner-control", onControl)
    window.addEventListener("runner-mute", () => this.audio.toggle())
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => window.removeEventListener("runner-control", onControl))

    this.hud = this.add.text(16, 16, "", {
      fontFamily: '"Press Start 2P", monospace',
      fontSize: "12px",
      color: "#f4e8c1"
    }).setScrollFactor(0).setDepth(20)
    this.banner = this.add.text(GAME_WIDTH / 2, GAME_HEIGHT / 2, "TAP / SPACE TO START", {
      fontFamily: '"Press Start 2P", monospace',
      fontSize: "16px",
      color: "#3ddc97",
      align: "center"
    }).setOrigin(0.5).setScrollFactor(0).setDepth(21)

    this.input.keyboard?.on("keydown-SPACE", () => this.tryStart())
    this.input.on("pointerdown", () => this.tryStart())
    this.time.addEvent({ delay: 2000, loop: true, callback: () => void this.eventsQueue.flush() })
    this.setState("START")
  }

  update(_time: number, delta: number) {
    this.drawHud()
    if (this.state !== "PLAYING") {
      if (this.player?.body) this.player.setVelocityX(0)
      return
    }

    const onGround = this.player.body.blocked.down || this.player.body.touching.down
    if (onGround) this.coyote = 120
    else this.coyote -= delta

    const slow = this.time.now < this.slowUntil
    const speed = slow ? 110 : 230
    const left = this.cursors.left.isDown || this.wasd.A?.isDown || this.touch.left
    const right = this.cursors.right.isDown || this.wasd.D?.isDown || this.touch.right
    const jumpHeld = this.cursors.up.isDown || this.cursors.space.isDown || this.wasd.W?.isDown || this.wasd.SPACE?.isDown || this.touch.jump

    if (left) this.player.setVelocityX(-speed)
    else if (right) this.player.setVelocityX(speed)

    if (jumpHeld && this.coyote > 0 && this.player.body.velocity.y >= 0) {
      this.player.setVelocityY(-520)
      this.coyote = 0
      this.audio.play("jump")
    }

    if (this.time.now < this.invulnerableUntil) {
      this.player.setAlpha(Math.sin(this.time.now / 40) > 0 ? 1 : 0.35)
    } else {
      this.player.setAlpha(1)
    }

    this.foes.children.iterate((child) => {
      const foe = child as Phaser.Physics.Arcade.Sprite
      const spec = foe.getData("spec")
      if (!spec) return true
      if (foe.x < spec.minX) foe.setVelocityX(Math.abs(spec.speed))
      if (foe.x > spec.maxX) foe.setVelocityX(-Math.abs(spec.speed))
      return true
    })

    this.remaining = Math.max(0, this.bootstrap.config.duration_seconds - (this.time.now - this.startedAt) / 1000)
    if (this.remaining <= 0) {
      void this.endRun("finished", "GAME_OVER")
      return
    }

    if (this.player.y > GAME_HEIGHT - 8) {
      this.loseLife("fell")
      return
    }

    if (this.player.x >= this.goalX) {
      void this.endRun("completed", "LEVEL_COMPLETE")
      return
    }

    if (this.questionsAsked < this.bootstrap.config.max_questions_per_run && this.time.now >= this.nextQuestionAt) {
      void this.openQuestion()
    }
  }

  private tryStart() {
    if (this.state !== "START") return
    this.audio.unlock()
    this.setState("COUNTDOWN")
    this.banner.setText("3")
    void this.api.start()
    this.time.addEvent({
      delay: 1000,
      repeat: 2,
      callback: () => {
        const n = Number(this.banner.text)
        if (n > 1) this.banner.setText(String(n - 1))
        else {
          this.banner.setText("GO")
          this.time.delayedCall(400, () => {
            this.banner.setText("")
            this.startedAt = this.time.now
            this.nextQuestionAt = this.time.now + this.bootstrap.config.question_frequency_seconds * 1000
            this.setState("PLAYING")
          })
        }
      }
    })
  }

  private collect: Phaser.Types.Physics.Arcade.ArcadePhysicsCallback = (_player, object) => {
    const item = object as Phaser.Physics.Arcade.Sprite
    const kind = item.getData("kind") as string
    item.destroy()
    const eventType = kind === "ruby" ? "ruby_collected" : kind === "rails" ? "rails_collected" : kind === "boost" ? "boost_collected" : "special_collected"
    if (kind === "ruby") this.gems += 1
    this.applyEvent(eventType, { x: item.x, y: item.y })
    this.audio.play("collect")
  }

  private hitFoe: Phaser.Types.Physics.Arcade.ArcadePhysicsCallback = (_player, object) => {
    if (this.time.now < this.invulnerableUntil || this.state !== "PLAYING") return
    const foe = object as Phaser.Physics.Arcade.Sprite
    const spec = foe.getData("spec")
    if (spec?.type === "debt") {
      this.slowUntil = this.time.now + 1800
      this.applyEvent("technical_debt_hit", {})
      this.audio.play("damage")
      this.invulnerableUntil = this.time.now + 600
      return
    }
    const eventType = spec?.type === "prod-bug" ? "production_bug_hit" : "bug_hit"
    this.applyEvent(eventType, {})
    this.loseLife(eventType)
  }

  private applyEvent(eventType: string, metadata: Record<string, unknown>) {
    this.score += previewDelta(this.bootstrap.config, eventType)
    this.eventsQueue.record(eventType, metadata)
  }

  private loseLife(reason: string) {
    if (this.state !== "PLAYING") return
    this.lives -= 1
    this.invulnerableUntil = this.time.now + 1500
    this.applyEvent("life_lost", { reason, lives: this.lives })
    this.audio.play("damage")
    this.setState("LIFE_LOST")
    this.banner.setText(this.lives > 0 ? "OUCH" : "DOWN")
    this.player.setVelocity(0, 0)
    this.time.delayedCall(700, () => {
      if (this.lives <= 0) {
        void this.endRun("finished", "GAME_OVER")
        return
      }
      this.player.setPosition(this.spawn.x, this.spawn.y)
      this.banner.setText("")
      this.setState("PLAYING")
    })
  }

  private async openQuestion() {
    this.setState("QUESTION")
    this.nextQuestionAt = this.time.now + this.bootstrap.config.question_frequency_seconds * 1000
    this.questionsAsked += 1
    this.player.setVelocity(0, 0)
    try {
      const question = await this.api.challenge()
      this.scene.launch("QuestionScene", {
        question,
        onAnswer: async (key: string) => {
          const result = await this.api.answer(question.question_id, key)
          this.score += result.points_awarded
          if (result.correct) this.questionsCorrect += 1
          this.audio.play(result.correct ? "correct" : "wrong")
          return result
        },
        onDone: () => {
          this.scene.stop("QuestionScene")
          if (this.state === "QUESTION") this.setState("PLAYING")
        }
      })
    } catch {
      this.setState("PLAYING")
    }
  }

  private async endRun(outcome: "completed" | "finished", state: GameState) {
    if (this.finishing) return
    this.finishing = true
    if (outcome === "completed") this.applyEvent("level_completed", {})
    this.setState(state)
    this.banner.setText(state === "LEVEL_COMPLETE" ? "DEPLOYED!" : "GAME OVER")
    this.audio.play(state === "LEVEL_COMPLETE" ? "complete" : "wrong")
    await this.eventsQueue.flush()
    try {
      const payload = await this.api.finish(outcome, this.score)
      this.setState("RESULT")
      const points = payload.score?.points ?? this.score
      this.banner.setText(`RUN COMPLETE\n${points}`)
      this.time.delayedCall(1400, () => {
        window.location.href = this.api.resultUrl()
      })
    } catch {
      window.location.href = this.api.resultUrl()
    }
  }

  private setState(state: GameState) {
    this.state = state
    this.physics.world.isPaused = state !== "PLAYING"
  }

  private drawHud() {
    this.hud.setText(`SCORE ${this.score}   LIVES ${this.lives}   TIME ${Math.ceil(this.remaining)}\n${this.bootstrap.playerName} · ${this.gems} GEMS · Q ${this.questionsCorrect}/${this.questionsAsked}`)
  }
}

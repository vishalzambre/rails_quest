/**
 * Tiny generated arcade blips. Audio starts only after a user gesture.
 */
export class AudioSystem {
  private ctx: AudioContext | null = null
  muted = false

  unlock() {
    this.ctx ||= new AudioContext()
    if (this.ctx.state === "suspended") void this.ctx.resume()
  }

  toggle() {
    this.muted = !this.muted
    return this.muted
  }

  play(kind: "jump" | "collect" | "damage" | "correct" | "wrong" | "complete" | "high") {
    if (this.muted) return
    this.unlock()
    const ctx = this.ctx
    if (!ctx) return
    const now = ctx.currentTime
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)

    const tones: Record<string, [OscillatorType, number, number]> = {
      jump: ["square", 420, 0.12],
      collect: ["square", 760, 0.1],
      damage: ["sawtooth", 140, 0.22],
      correct: ["triangle", 880, 0.2],
      wrong: ["sawtooth", 110, 0.28],
      complete: ["triangle", 520, 0.4],
      high: ["square", 990, 0.35]
    }
    const [type, freq, dur] = tones[kind]
    osc.type = type
    osc.frequency.setValueAtTime(freq, now)
    gain.gain.setValueAtTime(0.05, now)
    gain.gain.exponentialRampToValueAtTime(0.001, now + dur)
    osc.start(now)
    osc.stop(now + dur)
  }
}

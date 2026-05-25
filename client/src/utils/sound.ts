class SoundManager {
  private audioCtx: AudioContext | null = null;
  private enabled = true;

  private getCtx() {
    if (!this.audioCtx) {
      this.audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
    return this.audioCtx;
  }

  playTone(freq: number, duration: number, type: OscillatorType = 'sine') {
    if (!this.enabled) return;
    try {
      const ctx = this.getCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type;
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + duration);
    } catch (e) {
      console.warn('Sound play failed:', e);
    }
  }

  check() {
    this.playTone(880, 0.1, 'sine');
    this.playTone(1100, 0.15, 'sine');
  }

  uncheck() {
    this.playTone(400, 0.1, 'sine');
  }

  complete() {
    // Victory chord
    this.playTone(523, 0.15, 'sine'); // C5
    setTimeout(() => this.playTone(659, 0.15, 'sine'), 100); // E5
    setTimeout(() => this.playTone(784, 0.25, 'sine'), 200); // G5
  }

  levelUp() {
    this.playTone(440, 0.1, 'square');
    setTimeout(() => this.playTone(554, 0.1, 'square'), 100);
    setTimeout(() => this.playTone(659, 0.1, 'square'), 200);
    setTimeout(() => this.playTone(880, 0.4, 'square'), 300);
  }

  notification() {
    this.playTone(600, 0.1, 'sine');
  }

  setEnabled(val: boolean) {
    this.enabled = val;
    localStorage.setItem('nexus_sound', String(val));
  }

  isEnabled() {
    return localStorage.getItem('nexus_sound') !== 'false';
  }
}

export const soundManager = new SoundManager();

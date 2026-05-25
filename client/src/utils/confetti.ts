import confetti from 'canvas-confetti';

export function fireConfetti(options?: confetti.Options) {
  const defaults = {
    particleCount: 100,
    spread: 70,
    origin: { y: 0.6 },
    colors: ['#6366f1', '#10b981', '#f59e0b', '#f43f5e', '#06b6d4'],
    ...options,
  };
  confetti(defaults);
}

export function fireLevelUpConfetti() {
  const duration = 3000;
  const end = Date.now() + duration;

  const frame = () => {
    confetti({
      particleCount: 5,
      angle: 60,
      spread: 55,
      origin: { x: 0 },
      colors: ['#6366f1', '#8b5cf6', '#10b981'],
    });
    confetti({
      particleCount: 5,
      angle: 120,
      spread: 55,
      origin: { x: 1 },
      colors: ['#6366f1', '#8b5cf6', '#10b981'],
    });

    if (Date.now() < end) {
      requestAnimationFrame(frame);
    }
  };
  frame();
}

export function fireStreakConfetti() {
  confetti({
    particleCount: 150,
    spread: 100,
    origin: { y: 0.5 },
    colors: ['#f59e0b', '#fbbf24', '#fcd34d'],
    shapes: ['star'],
    scalar: 1.2,
  });
}

// Sound alert utility for tamper detection
// Uses Web Audio API to generate alert tones

class SoundAlert {
  private audioContext: AudioContext | null = null;
  private enabled: boolean = true;

  constructor() {
    // Create AudioContext only when needed (user gesture required)
    if (typeof window !== 'undefined') {
      this.initAudioContext();
    }
  }

  private initAudioContext() {
    try {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    } catch (e) {
      console.warn('Web Audio API not supported');
    }
  }

  // Play a warning beep for tamper alerts
  playTamperAlert() {
    if (!this.enabled || !this.audioContext) return;

    try {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      // Create an urgent warning tone (two-tone alert)
      oscillator.frequency.value = 800; // Higher frequency for urgency
      gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2);

      oscillator.start(this.audioContext.currentTime);
      oscillator.stop(this.audioContext.currentTime + 0.2);

      // Second tone
      setTimeout(() => {
        const oscillator2 = this.audioContext!.createOscillator();
        const gainNode2 = this.audioContext!.createGain();

        oscillator2.connect(gainNode2);
        gainNode2.connect(this.audioContext!.destination);

        oscillator2.frequency.value = 1000;
        gainNode2.gain.setValueAtTime(0.3, this.audioContext!.currentTime);
        gainNode2.gain.exponentialRampToValueAtTime(0.01, this.audioContext!.currentTime + 0.2);

        oscillator2.start(this.audioContext!.currentTime);
        oscillator2.stop(this.audioContext!.currentTime + 0.2);
      }, 250);
    } catch (e) {
      console.error('Failed to play alert sound:', e);
    }
  }

  // Play a success sound for unlock confirmation
  playUnlockSuccess() {
    if (!this.enabled || !this.audioContext) return;

    try {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      oscillator.frequency.value = 600;
      oscillator.type = 'sine';
      gainNode.gain.setValueAtTime(0.2, this.audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.3);

      oscillator.start(this.audioContext.currentTime);
      oscillator.stop(this.audioContext.currentTime + 0.3);
    } catch (e) {
      console.error('Failed to play success sound:', e);
    }
  }

  enable() {
    this.enabled = true;
    if (!this.audioContext) {
      this.initAudioContext();
    }
  }

  disable() {
    this.enabled = false;
  }

  isEnabled() {
    return this.enabled;
  }
}

// Singleton instance
export const soundAlert = new SoundAlert();

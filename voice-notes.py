#!/usr/bin/env python3
"""
Voice-to-text academic note transcription
Hold SPACE to record, release to transcribe
"""

import sys
import os
import whisper
import sounddevice as sd
import soundfile as sf
import numpy as np
from datetime import datetime
from pathlib import Path
import tempfile
import argparse
import threading
import time

# Academic context for your work
ACADEMIC_CONTEXT = """
Academic philosophical notes on Clarice Lispector, William Desmond, and metaxological thought.

Core concepts: metaxu, metaxological, the between, double mediation, porosity, passio essendi,
conatus essendi, pharmakon, dosis, kenosis, metanoia, apophasis, phasis, suchness,
dark intelligibility, hyperintelligible, idiocy of being, astonishment, counterfeit doubles,
reconfigured ethos, primal ethos, sunyata, transtheism, no-sive-yes, companionability.

Desmond's Four Ways: univocal, equivocal, dialectical, metaxological.
Desmond's concepts: agapeic astonishment, compassare, absolved relativity, familiar middle,
perplexing middle, astonishing middle, plurivocal, communication of being, ontological surplus.

Key thinkers: Clarice Lispector, William Desmond, Keiji Nishitani, Meister Eckhart, Rilke,
Rainer Maria Rilke, Teresa of Avila, Hildegard of Bingen, Julian of Norwich, Augustine,
Jacques Derrida, Bernard Stiegler, Heidegger, Hegel, Schelling, Plotinus, John Vervaeke,
Gabor Maté, Otto Lara Resende.

Works: The Passion According to G.H., Breath of Life, A Breath of Life, God and the Between,
Being and the Between, Religion and Nothingness, Interior Castle, Phaedrus.

Lispector phrases: "the worse truth", "without words", "thing-part", "inhuman intimacy",
"saltless truth", "neutral being", "radiant indifference", "sweet and abysmal vertigo".

Format: When saying "page X" transcribe as "p. X".
Preserve philosophical precision, contemplative tone, and poetic phrasing.
"""

class VoiceRecorder:
    def __init__(self, model_size="base", sample_rate=16000):
        print("Loading Whisper model... (this may take a moment)")
        self.model = whisper.load_model(model_size)
        self.sample_rate = sample_rate
        self.is_recording = False
        self.recording_buffer = []
        self.lock = threading.Lock()

    def start_recording(self):
        """Start recording audio"""
        with self.lock:
            self.is_recording = True
            self.recording_buffer = []

        def callback(indata, frames, time_info, status):
            if status:
                print(f"Status: {status}", file=sys.stderr)
            if self.is_recording:
                self.recording_buffer.append(indata.copy())

        self.stream = sd.InputStream(
            samplerate=self.sample_rate,
            channels=1,
            dtype='float32',
            callback=callback
        )
        self.stream.start()

    def stop_recording(self):
        """Stop recording and return audio data"""
        with self.lock:
            self.is_recording = False

        if hasattr(self, 'stream'):
            self.stream.stop()
            self.stream.close()

        if self.recording_buffer:
            return np.concatenate(self.recording_buffer)
        return None

    def transcribe_audio(self, audio_data):
        """Transcribe audio using Whisper"""
        if audio_data is None or len(audio_data) == 0:
            return ""

        # Save to temporary file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            temp_path = f.name
            sf.write(temp_path, audio_data, self.sample_rate)

        try:
            # Transcribe
            result = self.model.transcribe(
                temp_path,
                language="en",
                initial_prompt=ACADEMIC_CONTEXT
            )
            return result["text"].strip()
        finally:
            os.unlink(temp_path)

    def save_to_markdown(self, text, output_dir="05 Beasts"):
        """Save transcription to markdown file"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        filename = f"voice-note-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"

        output_path = Path(output_dir) / filename
        output_path.parent.mkdir(parents=True, exist_ok=True)

        content = f"# Voice Note\n\n*Transcribed: {timestamp}*\n\n{text}\n"

        with open(output_path, 'w') as f:
            f.write(content)

        return output_path

def print_instructions():
    print("\n" + "="*60)
    print("VOICE NOTE TRANSCRIPTION")
    print("="*60)
    print("\nInstructions:")
    print("  • Hold RIGHT ALT (Option) to record")
    print("  • Release to stop and transcribe")
    print("  • Type 'q' to quit")
    print("  • Type 's' to save current session")
    print("\nReady to record...\n")

def main():
    parser = argparse.ArgumentParser(description="Voice-to-text academic notes")
    parser.add_argument("--model", default="base",
                       choices=["tiny", "base", "small", "medium", "large"],
                       help="Whisper model size (default: base)")
    parser.add_argument("--output", default="05 Beasts",
                       help="Output directory for markdown files")
    args = parser.parse_args()

    recorder = VoiceRecorder(model_size=args.model)
    session_text = []

    print_instructions()

    try:
        from pynput import keyboard

        space_pressed = False

        def on_press(key):
            nonlocal space_pressed
            try:
                if key == keyboard.Key.alt_r and not space_pressed:
                    space_pressed = True
                    print("● Recording... (release to stop)", end='', flush=True)
                    recorder.start_recording()
            except Exception as e:
                pass

        def on_release(key):
            nonlocal space_pressed

            try:
                # Handle alt release
                if key == keyboard.Key.alt_r and space_pressed:
                    space_pressed = False
                    print("\r○ Stopped. Transcribing...                    ")

                    audio_data = recorder.stop_recording()
                    if audio_data is not None and len(audio_data) > 0:
                        text = recorder.transcribe_audio(audio_data)
                        if text:
                            print(f"\n→ {text}\n")
                            session_text.append(text)
                    else:
                        print("(no audio captured)\n")

                # Handle other keys (only when not holding space)
                elif not space_pressed:
                    if hasattr(key, 'char'):
                        if key.char == 'q':
                            print("\nQuitting...")
                            return False  # Stop listener
                        elif key.char == 's':
                            if session_text:
                                full_text = "\n\n".join(session_text)
                                path = recorder.save_to_markdown(full_text, args.output)
                                print(f"\n✓ Saved to: {path}\n")
                                session_text.clear()
                            else:
                                print("\nNothing to save yet!\n")
            except Exception as e:
                pass

        # Start keyboard listener
        with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
            listener.join()

    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    finally:
        # Auto-save on exit if there's content
        if session_text:
            print("\nAuto-saving session...")
            full_text = "\n\n".join(session_text)
            path = recorder.save_to_markdown(full_text, args.output)
            print(f"✓ Saved to: {path}")

if __name__ == "__main__":
    main()

# Voice Notes Transcription System

A push-to-talk voice transcription tool optimized for academic note-taking, using OpenAI's Whisper for local speech-to-text conversion.

## Setup

### Initial Installation

1. **Create virtual environment and install dependencies:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install openai-whisper sounddevice soundfile pynput
   ```

2. **Grant microphone permissions:**
   - macOS will prompt for microphone access on first run
   - Go to System Settings → Privacy & Security → Microphone
   - Enable access for Terminal/iTerm/your terminal app

### First Run

The first time you run the script, Whisper will download its model files (~140MB for base model):

```bash
./voice-notes.sh
```

Model files are cached in `~/.cache/whisper/` for future use.

## Usage

### Basic Recording

```bash
./voice-notes.sh
```

**Controls:**
- **Hold RIGHT ALT (Option)** → Start recording
- **Release RIGHT ALT** → Stop recording and transcribe
- **Type `s`** → Save current session to markdown file
- **Type `q`** → Quit (auto-saves if content exists)

### Model Options

Choose different Whisper models for accuracy vs. speed:

```bash
# Fastest, least accurate
./voice-notes.sh --model tiny

# Balanced (default)
./voice-notes.sh --model base

# More accurate, slower
./voice-notes.sh --model medium

# Best accuracy, slowest
./voice-notes.sh --model large
```

### Custom Output Directory

```bash
./voice-notes.sh --output "path/to/notes"
```

Default output: `05 Beasts/`

## Output Format

Transcriptions are saved as markdown files with timestamps:

```markdown
# Voice Note

*Transcribed: 2025-10-10 10:37*

Your transcribed text here...
```

Filename format: `voice-note-YYYYMMDD-HHMMSS.md`

## Academic Context

The transcription system is optimized for philosophical and academic terminology:

**Recognized terms:**
- metaxu, equivocal, plurivocal, passio essendi, conatus essendi
- pharmakon, kenosis, metanoia, apophasis, phasis
- suchness, porosity, dark intelligibility
- counterfeit doubles, double mediation, hyperintelligible
- idiocy of being, astonishment

**Recognized names:**
- Clarice Lispector, William Desmond, Keiji Nishitani
- Meister Eckhart, Rilke, Teresa of Avila
- Hildegard, Julian of Norwich, Augustine
- Derrida, Stiegler

**Recognized works:**
- The Passion According to G.H.
- Breath of Life
- God and the Between
- Being and the Between
- Interior Castle
- Phaedrus

## Post-Processing

Raw transcriptions may contain minor errors. For cleanup:

1. Record your notes normally
2. Review the generated markdown file
3. Use Claude Code session for manual cleanup:
   - Shows raw transcription
   - Fixes transcription errors
   - Adds proper quotation marks
   - Formats page references (p. 36)
   - Preserves philosophical precision and tone

## Troubleshooting

### Microphone not working
- Check System Settings → Privacy & Security → Microphone
- Restart terminal after granting permissions
- Ensure no other app is using the microphone

### Model download fails
- Check internet connection
- Models download to `~/.cache/whisper/`
- Try manually: `python -c "import whisper; whisper.load_model('base')"`

### Keyboard not responding
- Ensure script has accessibility permissions
- Try restarting terminal
- Check that pynput is installed: `pip list | grep pynput`

### Poor transcription quality
- Use a better model: `--model medium` or `--model large`
- Speak clearly and at moderate pace
- Minimize background noise
- Keep microphone distance consistent

## Technical Details

- **Whisper model:** OpenAI's open-source speech recognition
- **Audio format:** 16kHz mono WAV
- **Keyboard handling:** pynput library
- **Audio capture:** sounddevice library
- **All processing:** Local (no API calls)

## Files

- `voice-notes.py` - Main Python script
- `voice-notes.sh` - Wrapper to activate venv
- `.venv/` - Python virtual environment (gitignored)
- `05 Beasts/*.md` - Output transcriptions

## Notes

- Transcriptions are auto-saved on exit if unsaved content exists
- Hold Alt/Option throughout your entire thought/sentence for best results
- The script captures audio only while the key is held
- Session accumulates multiple recordings until saved or quit

#!/bin/bash
# Wrapper script to activate venv and run voice notes

cd "$(dirname "$0")"
source .venv/bin/activate
python voice-notes.py "$@"

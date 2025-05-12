# backend/speak_xtts.py
import sys
from TTS.api import TTS
from scipy.io.wavfile import write
import subprocess
import os
import numpy as np

text = sys.argv[1]
output_path = "xtts_output.wav"
voice_sample = os.path.join("backend", "reference.wav")

tts = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2", progress_bar=False, gpu=True)

audio_output = tts.tts(text=text, speaker_wav=voice_sample, language="en")

if isinstance(audio_output, np.ndarray):
    audio = audio_output
elif isinstance(audio_output, list):
    if all(isinstance(chunk, np.ndarray) for chunk in audio_output):
        audio = np.concatenate(audio_output)
    elif all(isinstance(sample, (float, int, np.floating)) for sample in audio_output):
        audio = np.array(audio_output, dtype=np.float32)
    else:
        raise ValueError("XTTS returned a mixed or unexpected list format.")
else:
    raise TypeError(f"Unexpected XTTS return type: {type(audio_output)}")

write(output_path, 24000, audio)
subprocess.run(["aplay", output_path])

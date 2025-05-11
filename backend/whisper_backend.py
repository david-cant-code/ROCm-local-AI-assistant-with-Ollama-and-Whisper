import whisper
import os
import sys
import argparse
import json
import warnings

# Suppress all warnings (e.g. from torch, transformers)
warnings.filterwarnings("ignore")

def transcribe_audio(file_path, model_size, output_dir, output_filename=None):
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    filename = output_filename if output_filename else base_name + ".txt"
    output_path = os.path.join(output_dir, filename)

    try:
        model = whisper.load_model(model_size)
        model = model.to("cuda")

        result = model.transcribe(file_path, verbose=False, language='en')

        full_text = " ".join([s["text"].strip() for s in result["segments"]])

        with open(output_path, "w", encoding="utf-8") as f:
            f.write(full_text)

        print(json.dumps({
            "status": "success",
            "output_file": output_path,
            "transcript": full_text
        }))
        sys.stdout.flush()

    except Exception as e:
        print(json.dumps({
            "status": "error",
            "message": str(e)
        }))
        sys.stdout.flush()
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transcribe audio using Whisper.")
    parser.add_argument("file_path", help="Path to the audio file")
    parser.add_argument("model_size", help="Size of Whisper model (e.g., base, small, medium)")
    parser.add_argument("output_dir", help="Directory to save the transcription")
    parser.add_argument("--output_filename", help="Optional filename for the output", default=None)

    args = parser.parse_args()

    transcribe_audio(args.file_path, args.model_size, args.output_dir, args.output_filename)

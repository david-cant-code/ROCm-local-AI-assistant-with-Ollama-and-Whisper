#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

#OS 
sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl git build-essential make \
  ffmpeg alsa-utils \
  libgtk-3-0 libnss3 libxss1 libasound2t64 libatk-bridge2.0-0 libcups2 \
  libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 libdrm2 libgbm1 \
  libxcb-dri3-0 libxkbfile1 libxfixes3 libxi6 libxtst6 libglib2.0-0 \
  nodejs npm

# Build deps for compiling CPython via pyenv
sudo apt-get install -y \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
  libncursesw5-dev tk-dev libffi-dev liblzma-dev xz-utils wget llvm \
  libxml2-dev libxmlsec1-dev

# pyenv install 
if [ ! -d "${HOME}/.pyenv" ]; then
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

PYVER="3.11.9"
if ! pyenv versions --bare | grep -qx "${PYVER}"; then
  pyenv install "${PYVER}"
fi
# Respect repo local version
pyenv local "${PYVER}"

python -V  # sanity check; should be 3.11.x

# Node
npm install

# Backend venv Whisper
python -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip

# optional commented out CPU if you want it

# ROCm (AMD GPU, ROCm 5.7 runtime present):
pip install --index-url https://download.pytorch.org/whl/rocm5.7 \
  torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1

# CPU-only (uncomment this block and comment the ROCm block above if you don't have ROCm):
# pip install --index-url https://download.pytorch.org/whl/cpu \
#   torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1

# Project requirements
pip install -r backend/requirements.txt
deactivate

# TTS venv (XTTS)
python -m venv tts-venv
source tts-venv/bin/activate
python -m pip install --upgrade pip


# ROCm:
pip install --index-url https://download.pytorch.org/whl/rocm5.7 \
  torch==2.3.1 torchaudio==2.3.1

# CPU:
# pip install --index-url https://download.pytorch.org/whl/cpu \
#   torch==2.3.1 torchaudio==2.3.1

# Coqui TTS + SciPy (XTTS v2)
pip install TTS==0.22.0 scipy
deactivate

echo "Setup complete. Start the app with: npm start"

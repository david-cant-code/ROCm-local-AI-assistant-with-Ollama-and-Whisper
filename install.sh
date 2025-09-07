#!/bin/bash

echo ""
echo "Push to Talk Ollama with Whisper"
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Remember, you should NEVER run a script that you got from the internet without reading it first"
echo "that means you should read this script before you run it, I could be an idiot and/or malicious"
echo "and the idiot option is likely"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
echo ""

# detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cant figure out the OS, but dont worry buddy"
    echo "You can install dependencies manually"
    exit 1
fi

# install system packages
install_debian_packages() {
    echo "Installing packages for Debian/Ubuntu, enter password when prompted"
    echo "Dont forget to read the script first so you know what youre installing"
    sudo apt update
    sudo apt install -y python3.12 python3-pip python3.12-venv python3-tk ffmpeg nodejs npm
    sudo apt install -y \
      python3.12 \
      python3-pip \
      python3.12-venv \
      python3-tk \
      ffmpeg \
      nodejs \
      npm \
      libnss3 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libcups2 \
      libxss1 \
      libxcomposite1 \
      libxrandr2 \
      libxcursor1 \
      libxdamage1 \
      libxkbcommon0 \
      libxshmfence1 \
      libgbm1 \
      libasound2 \
      libdrm2 \
      libx11-xcb1 \
      libxtst6 \
      libxext6 \
      libegl1 \
      libgl1 \
      libgtk-3-0 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      xdg-utils \
      libdbus-glib-1-2 \
      libgconf-2-4 \
      alsa-utils      

}

install_fedora_packages() {
    echo "A recent update broke compatability with selinux systems, fix it if you can, sorry"
    echo "you can always run this inside a debian based distrobox, I tested it and that works"
}

if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    echo "Debian based:"
    read -p "Do you want to install required system packages now? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        install_debian_packages
    else
        echo "Skipping package installation."
    fi

elif [[ "$DISTRO" == "fedora" ]]; then
    echo "Fedora based:"
    echo "A recent Fedora update has started causing an selinux issue that is making this not work."
    echo "you should use a debian based system."
    echo "on Fedora, this will work inside a debain distrobox."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "it would be super cool if you want to help fix the fedora issue btw"
    sleep 2
    exit 1
    #read -p "Do you want to install required system packages now? (y/n): " confirm
    #if [[ "$confirm" =~ ^[Yy]$ ]]; then
    #    install_fedora_packages
    #else
    #    echo "Skipping package installation. You should install these on your own then:"
    #    echo "python3.12 python3-pip python3-virtualenv python3-tkinter ffmpeg git"
    #fi

else
    echo "Unsupported or undetected distribution, or I screwed up the script."
    echo "Please install dependencies manually:"
    exit 1
fi

# create venv
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "setting up python venv and installing python packages"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
sleep 1

# venv for whisper backend
python3.12 -m venv venv
source venv/bin/activate

# install python dependencies
pip install --upgrade pip
pip install -r backend/requirements.txt -c backend/constraints.txt --extra-index-url https://download.pytorch.org/whl/rocm5.7

# exit venv
deactivate

# venv for xtts backend
python3.12 -m venv tts-venv
source tts-venv/bin/activate

#install xtts
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7
pip install TTS

# exit venv
deactivate

# install node deps
npm install

echo "Setup complete. Run with npm start"

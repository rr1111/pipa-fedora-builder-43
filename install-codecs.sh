#!/bin/bash
# install some common codecs and libs
sudo dnf -y install ffmpeg-free aom libmpeg2 schroedinger
zenity --notification --text="done installing codecs"

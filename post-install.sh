#!/bin/bash

# install some common codecs and libs
zenity --password | sudo -S dnf -y install ffmpeg-free aom libmpeg2 schroedinger

# add flathub remote and install bazaar, resources
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub io.github.kolunmi.Bazaar net.nokyan.Resources

#notify of completion
zenity --notification --text="Done,
installed codecs, added flathub remote"

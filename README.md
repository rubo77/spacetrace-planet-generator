# Spacetrace Planet-Generator

## install

    sudo apt install xplanet xplanet-images pysatellites

Then copy the needed images for the planets with:

    cp /usr/share/pysatellites/images/* ~/.xplanet/images/

for xplanet see http://xplanet.sourceforge.net/README.config
and http://xplanet.sourceforge.net/README
defaults are defined in /usr/share/xplanet/config/default

## Color Maps

Thre is a set of png maps generated from https://github.com/Zarkonnen/GenGen
and then copied with

    m=0; for i in color_maps/gengen/*; do cp "$i" color_maps/colormap$m.jpg; m=$(( $m + 1 )); done

## usage

Just call `./planet.tcl`
this will start generating planets in the `planets` folder. there is a config file that stores the planet number so it will continue where it left of.
To start again with the first planet reset the counter with

    echo '0' > ./configs/planet_progress_count


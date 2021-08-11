#!/bin/bash
sudo cp bin/lq-release-linux /bin/lq
echo "Binary placed in /bin"

if [[ -d ~/.config/lq ]]
then
    read -p "Do you want to replace the config file with a default one? (y, n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        cp lq.conf ~/.config/lq/lq.conf
    fi
else
    mkdir ~/.config/lq
    cp lq.conf ~/.config/lq/lq.conf
    echo "Config file placed in ~/.config/lq"
fi

echo "Done."
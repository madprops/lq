sudo cp bin/lq-release-linux /bin/lq
echo "Binary placed in /bin"

if [[ -d ~/.config/lq ]]
then
    :
else
    mkdir ~/.config/lq
    cp lq.conf ~/.config/lq/lq.conf
    cp color_reference.png ~/.config/lq/color_reference.png
    echo "Config files placed in ~/.config/lq"
fi

echo "Done."
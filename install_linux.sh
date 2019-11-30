sudo cp bin/lq-release-linux /bin/lq
echo "Binary placed in /bin"

if [[ -d ~/.config/lq ]]
then
    :
else
    mkdir ~/.config/lq
    cp lq.conf ~/.config/lq/lq.conf
    echo "Config file placed in ~/.config/lq"
fi

echo "Done."
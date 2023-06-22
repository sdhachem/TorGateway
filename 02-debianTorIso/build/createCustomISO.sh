if [ $# -eq 1 ]
then
        IMAGE_NAME=$1
else
        echo "./createLive IMAGE_NAME"
        exit
fi

sudo apt-get update
sudo apt-get -y install  live-build
BUILD_DIR="../$IMAGE_NAME-live-build"

echo " BUILD = $BUILD_DIR"

sudo rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

cd $BUILD_DIR


sudo lb config noauto \
    --mode debian \
    --debian-installer none \
    --archive-areas "main contrib non-free" \
    --apt-indices false \
    --memtest none \
    --bootappend-live "boot=live swap config username=live "\
    "${@}"

# $ lb config --bootappend-live "boot=live components persistence persistence-encryption=luks"

sudo mkdir -p config/includes.chroot/opt/tor/release/
sudo cp -r ../build/release/* config/includes.chroot/opt/tor/release/

sudo cp ../build/0100-tor.hook.chroot  config/hooks/live/
sudo chmod +x config/hooks/live/0100-tor.hook.chroot 


sudo echo '! Packages Priority standard' > config/package-lists/desktop.list.chroot
#sudo echo 'task-gnome-desktop'  >> config/package-lists/desktop.list.chroot
sudo echo 'task-lxqt-desktop' >> config/package-lists/desktop.list.chroot
sudo echo 'p7zip-full' >> config/package-lists/desktop.list.chroot
sudo echo 'haveged' >> config/package-lists/desktop.list.chroot
sudo echo 'rng-tools' >> config/package-lists/desktop.list.chroot
sudo echo 'gparted' >> config/package-lists/desktop.list.chroot

sudo echo 'connman' >> config/package-lists/desktop.list.chroot
sudo echo 'network-manager' >> config/package-lists/desktop.list.chroot

#Install TOR
sudo echo 'tor' >> config/package-lists/desktop.list.chroot

#Utilities
sudo echo 'wget' >> config/package-lists/desktop.list.chroot
sudo echo 'openssh-server' >> config/package-lists/desktop.list.chroot

 
 
#echo "task-laptop" >> config/package-lists/desktop.list.chroot
#echo 'dconf-gsettings-backend  gsettings-desktop-schemas' >> config/package-lists/desktop.list.chroot


sudo lb build --verbose

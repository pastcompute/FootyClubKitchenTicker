#!/bin/bash
#
# Script for installing FootyClubKitchenTicker software
#
# This obviously needs to get onto the pi to do the rest of the work
#

# During development:
#
# export SCREENLY_GIT=ssh://club@192.168.1.27/~/develop/club/screenly-ose
# export TICKER_GIT=ssh://club@192.168.1.27/~/develop/club/FootyClubKitchenTicker
# rsync -v club@192.168.1.27:develop/club/FootyClubKitchenTicker/pi_installer.sh . 
#
# Also, add pi /etc to git...
#
#
SCREENLY_GIT=${SCREENLY_GIT:-https://github.com/andymc73/screenly-ose}
SCREENLY_TAG=Testing
TICKER_GIT=${TICKER_GIT:-https://github.com/andymc73/FootyClubKitchenTicker}
TICKER_DIR=$HOME/ticker
LOCAL_BRANCH=local_production
SCONFDIR=$HOME/.screenly
DEBUPDATE=0
UPGRADE=0

# If SCREENLY_DIR not set, apply a heuristic to check other defaults
if ! test -d "$SCREENLY_DIR" ; then
  SCREENLY_DIR=$HOME/screenly-ose
fi

# Update software while working
test -d $SCREENLY_DIR || git clone $SCREENLY_GIT $SCREENLY_DIR
pushd $SCREENLY_DIR
git fetch origin
git branch $LOCAL_BRANCH $SCREENLY_TAG
git stash
git checkout $LOCAL_BRANCH
git rebase origin $LOCAL_BRANCH 
# TODO - rebase etc.
popd

test -d $TICKER_DIR || git clone $TICKER_GIT $TICKER_DIR
pushd $TICKER_DIR
git fetch origin
git branch $LOCAL_BRANCH master
git stash
git checkout $LOCAL_BRANCH
git rebase origin $LOCAL_BRANCH 
popd

# Make confdir if doesnt exist, and use git to keep track of upgrades
test -d $SCONFDIR || ( mkdir -p $SCONFDIR && cd $SCONFDIR && git init && touch .stamp && git add .stamp && git commit -m "initial" )

# Install system stuff if needed
# Dont bother backup stuff up, because I will put /etc in git on the dev machine...
if [ "$1" == "system-install" ] ; then

  set -e

  if [ $DEBUPDATE -eq 1 ] ; then sudo apt-get update ; fi
  if [ $UPGRADE -eq 1 ] ; then sudo apt-get upgrade ; fi
  sudo apt-get -y install \
        rsync git-core python-pip python-netifaces python-simplejson \
        python-imaging python-dev uzbl sqlite3 supervisor omxplayer \
        x11-xserver-utils libx11-dev watchdog chkconfig feh vim di htop xterm \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-terminus x11-apps \
        ticker wmctrl fonts-inconsolatahttps://wiki.archlinux.org/index.php/Xterm
        # xfonts-traditional 
  sudo pip install -r "$SCREENLY_DIR/requirements.txt" 


  sudo modprobe bcm2708_wdog
  sudo grep -q bcm2708_wdog /etc/modules || sed '$ i\bcm2708_wdog' -i /etc/modules
  sudo chkconfig watchdog on
  sudo sed -e 's/#watchdog-device/watchdog-device/g' -i /etc/watchdog.conf
  sudo /etc/init.d/watchdog start

  echo "Adding Screenly to autostart (via Supervisord)"
  sudo rsync -v "$SCREENLY_DIR/misc/supervisor_screenly.conf" /etc/supervisor/conf.d/screenly.conf
  sudo sed -i /etc/supervisor/conf.d/screenly.conf -e '/^directory=/ s@^directory=.*@directory='$SCREENLY_DIR'@'
  sudo sed -i /etc/supervisor/conf.d/screenly.conf -e '/^command=/ s@^command=.*@command='$SCREENLY_DIR'/server.py@'
  sudo /etc/init.d/supervisor stop > /dev/null
  sudo /etc/init.d/supervisor start > /dev/null

  sudo sed -e 's/^#xserver-command=X$/xserver-command=X -nocursor/g' -i /etc/lightdm/lightdm.conf

  sudo grep -q quiet /boot/cmdline.txt || sed '/quiet/ s/$/ quiet/' -i /boot/cmdline.txt

  [ -f /etc/xdg/lxsession/LXDE/autostart ] && sudo mv /etc/xdg/lxsession/LXDE/autostart /etc/xdg/lxsession/LXDE/autostart.bak

  set +e

fi

# Upgrade system config
pushd $SCREENLY_DIR

rsync -v misc/screenly.conf $SCONFDIR
sed -e "s@debug_logging = False@debug_logging = True@" -i $SCONFDIR/screenly.conf

popd

( cd $SCONFDIR ; git add screenly.conf ; git commit -m "Upgraded" )

mkdir -p $HOME/.config/lxsession/LXDE/
rm -f $HOME/.config/lxsession/LXDE/autostart
echo "@$TICKER_DIR/xticker.sh" > $HOME/.config/lxsession/LXDE/autostart
echo "@$SCREENLY_DIR/misc/xloader.sh" >> $HOME/.config/lxsession/LXDE/autostart

mkdir -p ~/.config/openbox
mkdir -p ~/.config/lxpanel/LXDE/panels
rsync -v "$SCREENLY_DIR/misc/gtkrc-2.0" ~/.gtkrc-2.0
rsync -v "$SCREENLY_DIR/misc/lxde-rc.xml" ~/.config/openbox/lxde-rc.xml
[ -f ~/.config/lxpanel/LXDE/panels/panel ] && mv ~/.config/lxpanel/LXDE/panels/panel ~/.config/lxpanel/LXDE/panels/panel.bak

# Should be done in git now. chmod +x "$SCREENLY_DIR/server.py"

# Now, the ticker... 
# http://forum.porteus.org/viewtopic.php?f=53&t=1013
#xterm*faceName:           terminus:bold:pixelsize=14
# https://wiki.archlinux.org/index.php/Xterm
cat > ~/.Xdefaults <<EOF
XTerm*dynamicColors:      true
EOF
fc-cache
xrdb -merge ~/.Xdefaults

rsync -v ticker/splash_page_extra.haml "$SCREENLY_DIR/views"
rsync -v ticker/logo.jpg "$SCREENLY_DIR/static/img"


echo 'WARNING - fix .config/openbox/lxde-rc.xml such that application/maximized is no!'

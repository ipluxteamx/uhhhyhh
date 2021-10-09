#!/data/data/com.termux/files/usr/bin/bash
pkg install wget curl pv proot tar pulseaudio dos2unix -y
#Variables we need. Script is modular, change below variables to install different distro's
name="KDE Ubuntu Modded OS"
distro=androkde
folder=$distro-fs
url="https://andronix.online:8000/download?token=$token"
maxsize=$(curl -sI $url |awk 'tolower($0) ~ /content-length/ {print $2}' |dos2unix)
tarball=kde_ubuntu.tar.xz
echo " "
echo " "
echo "-----------------------------------------------------------"
echo "|  NOTE THAT ALL THE PREVIOUS UBUNTU DATA WILL BE ERASED  |"
echo "-----------------------------------------------------------"
echo "If you want to keep your old $distro press Ctrl - c now!! "
echo -n "5. "
sleep 1
echo -n "4. "
sleep 1
echo -n "3. "
sleep 1
echo -n "2. "
sleep 1 
echo -n "1. "
sleep 1 
echo "Removing $folder and $distro-binds"
rm -rf $distro-binds $folder
echo " "
echo "Proceeding with installation"
echo " "
echo  "Allow the Storage permission to termux"
echo " "
sleep 2
termux-setup-storage
clear

#Creating folders we need
mkdir -p $distro-binds $folder

#Performing a check for online or offline install
check=${token:-1}
if [ "$check" -eq "1" ] > /dev/null 2>&1; then
	echo "Local $distro rootfs found, extracting"
	echo ""
	if [ -x "$(command -v neofetch)" ]; then 
		neofetch --ascii_distro ubuntu -L
	fi
	echo ""
	pv $tarball | proot --link2symlink tar -Jxf - -C $folder || :
else
	echo "Downloading and extracting $name"
	echo "Extraction happens in parallel"
	echo ""
	if [ -x "$(command -v neofetch)" ]; then 
		neofetch --ascii_distro ubuntu -L
	fi
	echo ""
	wget -qO- --tries=0 $url|pv -s $maxsize|proot --link2symlink tar -Jxf - -C $folder || :
fi

bin=start-$distro.sh
if [ -d $folder/var ];then
	clear
	echo "--------------------------------------------------------"
	echo "|  Enabling Audio support in Termux and configuring it  |"
	echo "--------------------------------------------------------"
	if grep -q "anonymous" ~/../usr/etc/pulse/default.pa
	then
    		sed -i '/anonymous/d' ~/../usr/etc/pulse/default.pa
    		echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> ~/../usr/etc/pulse/default.pa
	else
    		echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> ~/../usr/etc/pulse/default.pa
	fi

	if grep -q "exit-idle" ~/../usr/etc/pulse/daemon.conf
	then
    		sed -i '/exit-idle/d' ~/../usr/etc/pulse/daemon.conf
    		echo "exit-idle-time = -1" >> ~/../usr/etc/pulse/daemon.conf
	else
    		echo "exit-idle-time = -1" >> ~/../usr/etc/pulse/daemon.conf
	fi
	echo "Done patching termux to enable audio playback"
	echo ""
	sleep 2
	echo "---------------------------"
	echo "|  Writing launch script  |"
	echo "---------------------------"

	cat > $bin <<- EOM
	#!/data/data/com.termux/files/usr/bin/bash
	cd \$(dirname \$0)
	## unset LD_PRELOAD in case termux-exec is installed
	pulseaudio -k >>/dev/null 2>&1
	pulseaudio --start >>/dev/null 2>&1
	unset LD_PRELOAD
	command="proot"
	command+=" --link2symlink"
	command+=" -0"
	command+=" -r $folder"
	if [ -n "\$(ls -A $distro-binds)" ]; then
    		for f in $distro-binds/* ;do
      		. \$f
    	done
	fi
	command+=" -b /dev"
	command+=" -b /proc"
	command+=" -b $folder/root:/dev/shm"
	## uncomment the following line to have access to the home directory of termux
	#command+=" -b /data/data/com.termux/files/home:/root"
	## uncomment the following line to mount /sdcard directly to /
	#command+=" -b /sdcard"
	command+=" -w /root"
	command+=" /usr/bin/env -i"
	command+=" HOME=/root"
	command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
	command+=" TERM=\$TERM"
	command+=" LANG=en_US.UTF-8"
	command+=" LC_ALL=C"
	command+=" LANGUAGE=en_US"
	command+=" /bin/bash --login"
	com="\$@"
	if [ -z "\$1" ];then
    		exec \$command
	else
    		\$command -c "\$com"
	fi
	EOM

	echo "-------------------------------"
	echo "|  Checking for file presence  |"
	echo "-------------------------------"
	echo ""

	if test -f "$bin"; then
    		echo "Boot script present"
		chmod +x $bin
    		echo " "
	fi

	FD=$folder
	if [ -d "$FD" ]; then
  		echo "Boot container present"
	  	echo " "
	fi

	UFD=$distro-binds
	if [ -d "$UFD" ]; then
  		echo "Sub-Boot container present"
	  	echo " "
	fi

	chmod 4755 $(find $folder -name sudo | grep bin)
	chmod 4755 $(find $folder -name su | grep bin)
	wget -qO $folder/usr/share/andronix/firstrun https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Rootfs/Ubuntu19/firstrun
	wget -qO $folder/usr/local/bin/vnc https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Rootfs/Ubuntu19/vnc
	wget -qO $folder/usr/local/bin/vncpasswd https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Rootfs/Ubuntu19/vncpasswd
	wget -qO $folder/usr/local/bin/vncserver-stop https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Rootfs/Ubuntu19/vncserver-stop
	wget -qO $folder/usr/local/bin/vncserver-start https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Rootfs/Ubuntu19/vncserver-start
	chmod +x $folder/usr/share/andronix/firstrun
	chmod +x $folder/usr/local/bin/*
	echo "Installation Finished"
	echo "Start $name with command ./start-$distro.sh"
else 
	echo "Installation unsuccessful"
	echo "Check network connectivity and contact devs on Discord if problems persist"
fi

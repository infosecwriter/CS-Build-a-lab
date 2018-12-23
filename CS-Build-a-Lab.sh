#!/bin/bash
# Build-a-lab (KVM/VirtualBox) v0.1.2
# Coded by: Cyber Secrets - Information Warfare Center
# Github: https://github.com/infosecwriter
# This just sets up the environment for KVM or VirtualBox and has a few extra items

trap 'printf "\n"; stop 1; exit 1' 2
clear

VINSTALL=""
echo "Setting up..."
#sudo apt update
# sudo apt-get install p7zip -y

startmenu() {
	banner
	printf "\e[92m  Build-a-Lab with KVM or VirtualBox...\n"
	printf "  The Libvirt/KVM Lab                                        =  1\n"
	printf "  The VirtualBox Lab                                         =  2\n"
	printf "  Download Vuln Virtual Machines to start building your lab! =  3\n"
	printf "  Convert VM file type                                       = 90\n"
	printf "  Compress VM file                                           = 91\n"
	printf "  Clean up Temp folder                                       = 92\n"
	printf "  Remove KVM/VirtualBox                                      = 98\n"
	printf "  Exit                                                       = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	stop 1;;
		1|01) 	kvmmenu ;;
		2|02) 	vbmenu ;;
		3|03) 	labmenu
			mkdir temp > /dev/null 2>&1
			;;

		90) 	read -p $'  File type to convert to "qcow2, vmdk, vdi, raw":' vmtype; 
			read -p $'  File to convert from: ' vmif;
			read -p $'  Output file name:' vmof;
			qemu-img convert -c -O $vmtype $vmif $vmof; read 'Press enter to continue.'; 
			startmenu ;; 
		91) 	read -p $'  File type to compress "qcow2, vmdk, vdi, raw": ' vmtype; 
			read -p $'  File to convert from: ' vmif;
			qemu-img convert -c -O $vmtype $vmif $vmif-1 && rm $vmif && mv $vmif-1 $vmif; read 'Press enter to continue.'; 
			startmenu ;; 
		92) 	rm -rf temp; 
			read 'Press enter to continue.'; 
			startmenu ;; 
		98) 	read -p $'  Remove KVM (1) or VirtualBox (2): ' vmremove
			case $vmremove in
			1|01)	sudo apt purge qemu-kvm libvirt-clients qemu-utils libvirt-daemon-system virt-manager && startmenu ;;
			2|02)	sudo apt purge virtualbox virtualbox-ext-pack && startmenu ;;
			*)
			startmenu ;; 
			esac ;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		startmenu
		;;
	esac
}

kvmmenu() {
	banner
	printf "\e[92m  Build-a-Lab with KVM or VirtualBox...\n"
	printf "  Install Libvirt/KVM                                        =  1\n"
	printf "  Run Virt-Manager                                           =  2\n"
	printf "  List KVM Virtual Machines                                  =  3\n"
	printf "  Start a headless KVM Virtual Machine                       =  4\n"
	printf "  Stop a headless KVM Virtual Machine                        =  5\n"
	printf "  Shut down ALL KVM Virtual Machines                         =  6\n"
	printf "  Compress ALL KVM Virtual Machines in VMs folder            = 10\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	startmenu;;
		1|01) 	sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove && sudo apt install qemu-kvm libvirt-clients qemu-utils libvirt-daemon-system virt-manager; kvmmenu ;;
		2|02) 	virt-manager; kvmmenu ;;
		3|03) 	kvmlist; kvmmenu ;;
		4|04) 	kvmlist; read -p $'Name the VM you want to start: ' val; virsh start $val && kvmmenu ;;
		5|05) 	kvmlist; read -p $'Name the VM you want to shutdown: ' val; virsh shutdown $val; sleep 30; virsh destroy $val; kvmmenu ;;
		6|06) 	echo "Try to cleanly shut down all running KVM domains..."
			touch /tmp/shutdown-kvm-guests
			virsh list | grep running | awk '{ print $2}' | while read DOMAIN; do
				virsh shutdown $DOMAIN
			done
			END_TIME=$(date -d "120 seconds" +%s)
			while [ $(date +%s) -lt $END_TIME ]; do
				printf "." 
				test -z "$(virsh list | grep running | awk '{ print $2}')" && break
				sleep 1
			done
			printf "\n"
			virsh list | grep running | awk '{ print $2}' | while read DOMAIN; do
				virsh destroy $DOMAIN
				sleep 3
			done
			kvmmenu
			;;
		10) 	ls -la --block-size=M ~/VMs/ | grep -e qcow2 | tee vm-pre-conv.txt
			ls ~/VMs/ | grep -e qcow2 | grep -v -e "-smallme." | awk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1' | while read convert; do
			printf "Compressing ~/VMs/$convert.qcow2...\n"
			qemu-img convert -O qcow2 -c ~/VMs/$convert.qcow2 ~/VMs/$convert-smallme.qcow2 && printf "...done\n" && rm ~/VMs/$convert.qcow2 && mv ~/VMs/$convert-smallme.qcow2 ~/VMs/$convert.qcow2 || "...failed\n"
			done
			ls -la --block-size=M ~/VMs/ | grep -e qcow2 | tee vm-conv.txt
			read -p $'Notice the size difference: ' Readme
			kvmmenu 
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		kvmmenu
		;;
	esac
}

kvmlist() {
	echo "KVM Virtual Machine IP Adress List:"
	virsh list | grep running | awk '{ print $2}' | while read DOMAIN; do
		printf "* $DOMAIN : "
		IP=$(virsh domifaddr $DOMAIN | grep ipv4 | awk '{print $4}')
		[ -z "$IP" ] && printf "No IP Address...\n"  || echo $IP
	done
	printf "\n"
	virsh list --all | tee VMs.txt
	read -p $'Press enter to continue.' val 
}

vbmenu() {
	banner
	printf "\e[92m  Build-a-Lab with KVM or VirtualBox...\n"
	printf "  Install Libvirt/KVM                                        =  1\n"
	printf "  Run Virt-Manager                                           =  2\n"
	printf "  List KVM Virtual Machines                                  =  3\n"
	printf "  Start a headless KVM Virtual Machine                       =  4\n"
	printf "  Stop a headless KVM Virtual Machine                        =  5\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	startmenu;;
		1|01) 	sudo apt-get update
			sudo apt-get dist-upgrade -y
			sudo apt-get autoremove -y
			sudo apt-get -y install gcc make linux-headers-$(uname -r) dkms
			sudo apt-get -y install virtualbox virtualbox-ext-pack 		
			startmenu;;
		2|02) 	virtualbox &
			vbmenu ;;
		3|03) 	VBoxManage list vms | tee VMs.txt; read -p $'Press enter to continue.' val; vbmenu ;;
		4|04) 	read -p $'Name the VM you want to start: ' val; VBoxManage startvm "$val" --type headless && vbmenu ;;
		5|05) 	read -p $'Name the VM you want to shutdown: ' val; VBoxManage controlvm "$val" poweroff --type headless && vbmenu ;;

  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		vbmenu
		;;
	esac
}


labmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
	printf "  Download Vulnerable Machines                               =  1\n"
	printf "  Download Red Team Distros                                  =  2\n"
#	printf "  Download Blue Team Distros                                 =  3\n"
#	printf "  Download Privacy Distros                                   =  4\n"
	printf "  Download Common Distros                                    =  5\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	mkdir temp > /dev/null 2>&1
	case $option in
		99) 	startmenu ;;
		1|01) 	vulnlabmenu ;;
		2|02) 	rtlabmenu ;;
		3|03) 	btlabmenu ;;
		4|04) 	privlabmenu ;;
		5|05)	comlabmenu ;;

		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		labmenu
		;;
	esac

}

vulnlabmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
	printf "  Download Metasploitable2 2 GB                              =  1\n"
	printf "  Download Impossible Mission Force (IMF) 1.6 GB             =  2\n"
	printf "  Download Necromancer 330 MB                                =  3\n"
	printf "  Download Mr Robot 740 MB                                   =  4\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	labmenu;;
		1|01) 	FOLDER="Metasploitable2-Linux"
			VMNAME="Metasploitable"
			VTYPE="vmdk"
			VOS="linux"
			VDOWN="https://download.vulnhub.com/metasploitable/metasploitable-linux-2.0.0.zip"
			FILE=temp/${VDOWN##*/}
			if [ ! -f $FILE ]; then
			   	wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			vulnlabmenu
			;;
		2|02)	FOLDER="IMF"
			VMNAME="IMF-disk1"
			VTYPE="vmdk"
			VOS="linux"
			VDOWN="https://download.vulnhub.com/imf/IMF.ova"
			FILE=temp/${VDOWN##*/}
			if [ ! -f $FILE ]; then
			   	mkdir temp/$FOLDER > /dev/null 2>&1
				wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			vulnlabmenu
			;;

		3|03)	FOLDER="Necromancer"
			VMNAME="necromancer-disk1"
			VTYPE="vmdk"
			VOS="OpenBSD_64"
			VDOWN="https://download.vulnhub.com/necromancer/necromancer.ova"
			FILE=temp/${VDOWN##*/}
			if [ ! -f $FILE ]; then
			   	mkdir temp/$FOLDER > /dev/null 2>&1 
				wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			vulnlabmenu
			;;
		4|04)	FOLDER="MrRobot"
			VMNAME="mrRobot-disk1"
			VTYPE="vmdk"
			VOS="linux"
			VDOWN="https://download.vulnhub.com/mrrobot/mrRobot.ova"
			FILE=temp/${VDOWN##*/}
			if [ ! -f $FILE ]; then
			   	mkdir temp/$FOLDER > /dev/null 2>&1
				wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			vulnlabmenu
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		vulnlabmenu
		;;
	esac


}

rtlabmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
	printf "  Download Kali Rolling 3.8GB                                =  2\n"
	printf "  Download Parrot Security 13.5 GB                           =  3\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	labmenu;;
		2|02) 	FOLDER="Kali-Rolling"
			VMNAME="Kali-Linux-2018.4-vbox-amd64-disk001"
			VTYPE="vmdk"
			VOS="debian"
			VDOWN="https://images.offensive-security.com/virtual-images/kali-linux-2018.4-vbox-amd64.ova"
			FILE=temp/${VDOWN##*/}
			printf " Username – root\n"
			printf " Password – toor\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			rtlabmenu
			;;
		3|03) 	FOLDER="Parrot_Security"
			VMNAME="Parrot_Security"
			VTYPE="vdi"
			VOS="debian"
			VDOWN="https://sourceforge.net/projects/osboxes/files/v/vb/40-P-rt/4.2.2/42264.7z"
			FILE=temp/${VDOWN##*/}
			printf " Username – osboxes\n"
			printf " Password – osboxes.org\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
				mv temp/$FOLDER/Parrot\ Security\ 4.2.2\ \(64bit\).vdi temp/$FOLDER/$VMNAME.vdi	
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			rtlabmenu
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		rtlabmenu
		;;
	esac
}

btlabmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
#	printf "  Download Debian                                            =  3\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	labmenu;;
		3|03) 	FOLDER="Debian"
			VMNAME="Debian_Stretch"
			VTYPE="vdi"
			VOS="debian"
			VDOWN="https://sourceforge.net/projects/osboxes/files/v/vb/14-D-b/9.5/9564.7z"
			FILE=temp/${VDOWN##*/}
			printf " Username – osboxes\n"
			printf " Password – osboxes.org\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
				mv temp/$FOLDER/Debian\ 9.5\ \(64bit\).vdi temp/$FOLDER/$VMNAME.vdi
				read "test"	
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			comlabmenu
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		btlabmenu
		;;
	esac
}

privlabmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
	printf "  Download Whonix Tor Gatway & Workstation 1.6GB             =  3\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	labmenu;;
		3|03) 	FOLDER="Whonix-Gateway"
			VMNAME="Whonix-Gateway-XFCE-14.0.0.9.9-disk001"
			VTYPE="vmdk"
			VOS="linux"
			VDOWN="https://download.whonix.org/linux//14.0.0.9.9/Whonix-Gateway-XFCE-14.0.0.9.9.ova"
			FILE=temp/${VDOWN##*/}
			printf " Username – user\n"
			printf " Password – changeme\n"
			if [ ! -f $FILE ]; then
			   	mkdir temp/$FOLDER > /dev/null 2>&1 
				wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			echo "  Go to the Whonix-Gateway terminal."
			echo "  Log in with the default credentials."
			echo "  Issue the command sudo su to log in as the root user."
			echo "  Issue the command passwd."
			echo "  Enter a new password."
			echo "  Confirm the new password."
			echo "  Issue the command passwd user."
			echo "  Enter a new password."
			echo "  Confirm the new password."
			buildvm

			echo " Now working on the workstation..."
			FOLDER="Whonix-Workstation"
			VMNAME="Whonix-Workstation-XFCE-14.0.0.9.9-disk001"
			VTYPE="vmdk"
			VOS="linux"
			VDOWN="https://download.whonix.org/linux//14.0.0.9.9/Whonix-Workstation-XFCE-14.0.0.9.9.ova"
			FILE=temp/${VDOWN##*/}
			printf " Username – user\n"
			printf " Password – changeme\n"
			if [ ! -f $FILE ]; then
			   	mkdir temp/$FOLDER > /dev/null 2>&1 
				wget -P temp $VDOWN
				unpack
			else
			   	echo " File $FILE exist."
			fi
			buildvm

			privlabmenu
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		privlabmenu
		;;
	esac
}

comlabmenu() {
	banner
	printf "\e[92m  Fill up your lab... (You need 3x the space for conversion)\n"
#	printf "  Download Kali Rolling                                      =  1\n"
	printf "  Download Black Lab 7.1GB                                   =  2\n"
	printf "  Download CentOS 4.8GB                                      =  3\n"
	printf "  Download Debian 6GB                                        =  4\n"
	printf "  Exit to Previous Menu                                      = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	labmenu;;
		2|02) 	FOLDER="Black_Lab"
			VMNAME="Black_Lab"
			VTYPE="vdi"
			VOS="linux"
			VDOWN="https://sourceforge.net/projects/osboxes/files/v/vb/6-Bl-Lb/11.60/116064.7z"
			FILE=temp/${VDOWN##*/}
			printf " Username – osboxes\n"
			printf " Password – osboxes.org\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
				mv temp/$FOLDER/CentOS\ 7-1804\ \(64bit\).vdi temp/$FOLDER/$VMNAME.vdi
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			comlabmenu
			;;
		3|03) 	FOLDER="CentOS"
			VMNAME="CentOS"
			VTYPE="vdi"
			VOS="linux"
			VDOWN="https://sourceforge.net/projects/osboxes/files/v/vb/10-C-nt/7/7-1804/180464.7z"
			FILE=temp/${VDOWN##*/}
			printf " Username – osboxes\n"
			printf " Password – osboxes.org\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
				mv temp/$FOLDER/Debian\ 9.5\ \(64bit\).vdi temp/$FOLDER/$VMNAME.vdi
				read "test"	
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			comlabmenu
			;;
		4|04) 	FOLDER="Debian"
			VMNAME="Debian_Stretch"
			VTYPE="vdi"
			VOS="debian"
			VDOWN="https://sourceforge.net/projects/osboxes/files/v/vb/14-D-b/9.5/9564.7z"
			FILE=temp/${VDOWN##*/}
			printf " Username – osboxes\n"
			printf " Password – osboxes.org\n"
			if [ ! -f $FILE ]; then
			   	wget -P temp wget -P temp $VDOWN
				mkdir temp/$FOLDER > /dev/null 2>&1
				unpack
				mv temp/$FOLDER/Debian\ 9.5\ \(64bit\).vdi temp/$FOLDER/$VMNAME.vdi
			else
			   	echo " File $FILE exist."
			fi
			buildvm
			comlabmenu
			;;
  		*)
		printf "\e[1;93m [!] Invalid option!\e[0m\n"
		clear
		comlabmenu
		;;
	esac
}

unpack() {

	case $FILE in
		*".zip"*)
			unzip -d temp $FILE ;;
		*".7z"*)
			7z e $FILE -otemp/$FOLDER ;;
		*".ova"*)
			tar -C temp/$FOLDER -xvf $FILE ;;
		*".rar"*)
			 ;;
		*)
		echo "No compression";;
	esac

}

buildvm() {
	read -p $' Set up for ONLY KVM (1) or VirtualBox (2): \e[37;1m' vmoption
	case $vmoption in
	1|01)	makekvm $FOLDER $VMNAME $VTYPE $VOS && virt-manager & ;;
	2|02)	makevb $FOLDER $VMNAME $VTYPE $VOS && virtualbox & ;;
	*)
	;;
	esac
}

makekvm() {
	mkdir ~/VMs > /dev/null 2>&1
	printf "\n Building VirtualBox disk and compressing $2.  May take a few minutes\n"
   	qemu-img convert -c -O qcow2 temp/$1/$2.$3 ~/VMs/$2.qcow2 || read -p $'Conversion failed...  The reason should be above.  Press Enter to Continue: ' ReadMe
	virt-install --name=$FOLDER --vcpus=1 --memory=1024 --disk ~/VMs/$VMNAME.qcow2 --os-type $VOS --os-variant generic --graphics spice,listen=127.0.0.1 --console pty,target_type=serial $VINSTALL --import 
}

makevb() {

	if [[ $VDOWN == *".ova"* ]]; then
		CONVB=$(echo $FILE | cut -d"/" -f2 | cut -d"." -f1)
		VBoxManage import $FILE
		#VBoxManage startvm $CONVB
		virtualbox	
	else

		mkdir ~/VirtualBox\ VMs/$1
		printf "Building VirtualBox disk\n"
		cp temp/$1/$2.$3 ~/VirtualBox\ VMs/$1
		cd ~/VirtualBox\ VMs
		VBoxManage createvm --name $1 --ostype $4 --register
		VBoxManage modifyvm $1 --memory 512
		modifyvm $1 --vtxvpid off
		VBoxManage storagectl $1 --name "IDE Controller" --add ide --controller PIIX4
		VBoxManage storageattach $1 --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium ~/VirtualBox\ VMs/$1/$2.vmdk
		VBoxManage startvm $1
	fi
}


stop() {
# 	Cleaning up your mess
	printf "\nCleaning up\n"
	rm -rf temp
}

banner() {
	clear
	printf "\n"
	printf "\e[1;93m    .:.:.\e[0m\e[1;77m Build-a-Lab with KVM or VirtualBox              \e[0m\e[1;93m.:.:.\e[0m\n"
	printf "\e[1;93m    .:.:.\e[0m\e[1;77m Tool coded by: @InfoSecWriter                   \e[0m\e[1;93m.:.:.\e[0m\n"
	printf "\e[1;93m    .:.:.\e[0m\e[1;77m https://github.com/infosecwriter/               \e[0m\e[1;93m.:.:.\e[0m\n"
	printf "\e[1;93m    .:.:.\e[0m\e[1;77m CyberSecrets.org : IntelligentHacking.com       \e[0m\e[1;93m.:.:.\e[0m\n"
	printf "\n"
	printf "  \e[101m\e[1;77m:: VirtualBox does not play well with KVM.                   ::\e[0m\n"
	printf "  \e[101m\e[1;77m:: Pick KVM or VirtualBox or run VirtualBox first...         ::\e[0m\n"
	printf "\n"
}

banner
startmenu

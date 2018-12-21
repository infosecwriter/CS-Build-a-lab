#!/bin/bash
# Build-a-lab (KVM/VirtualBox) v0.1.2
# Coded by: Cyber Secrets - Information Warfare Center
# Github: https://github.com/infosecwriter
# This just sets up the environment for KVM or VirtualBox and has a few extra items

trap 'printf "\n"; stop 1; exit 1' 2
clear

trap 'printf "\n"; stop 1; exit 1' 2
clear

startmenu() {
	banner
	printf "\e[92m  Build-a-Lab with KVM or VirtualBox...\n"
	printf "  Install Libvirt/KVM                                        =  1\n"
	printf "  Run Virt-Manager                                           =  2\n"
	printf "  List KVM Virtual Machines                                  =  3\n"
	printf "  Start a headless KVM Virtual Machine                       =  4\n"
	printf "  Stop a headless KVM Virtual Machine                        =  5\n"
	printf "  Install VirtualBox                                         = 11\n"
	printf "  Run VirtualBox                                             = 12\n"
	printf "  List VirtualBox Virtual Machines                           = 13\n"
	printf "  Start a headless VirtualBox Virtual Machine                = 14\n"
	printf "  Stop a headless VirtualBox Virtual Machine                 = 15\n"
	printf "  Download Metasploitable2 2 GB                              = 50\n"
	printf "  Download Impossible Mission Force (IMF) 1.6 GB             = 52\n"
	printf "  Download Necromancer 330 MB                                = 53\n"
	printf "  Download Mr Robot 740 MB                                   = 54\n"
	printf "  Convert VM file type                                       = 90\n"
	printf "  Compress VM file                                           = 91\n"
	printf "  Clean up Temp folder                                       = 92\n"
	printf "  Remove KVM/VirtualBox                                      = 98\n"
	printf "  Exit                                                       = 99\n"
	printf "\n"
	read -p $'  Choose an option: \e[37;1m' option
	case $option in
		99) 	stop 1;;
		1|01) 	sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove && sudo apt install qemu-kvm libvirt-clients qemu-utils libvirt-daemon-system virt-manager; startmenu ;;
		2|02) 	virt-manager; startmenu ;;
		3|03) 	echo "KVM Virtual Machine IP Adress List:"
			# List IP addresses of VMs.
			virsh list | grep running | awk '{ print $2}' | while read DOMAIN; do
				printf "* $DOMAIN : "
				IP=$(virsh domifaddr $DOMAIN | grep ipv4 | awk '{print $4}')
				[ -z "$IP" ] && printf "No IP Address...\n"  || echo $IP
			done
			printf "\n"
			virsh list --all | tee VMs.txt
			read -p $'Press enter to continue.' val
			startmenu 
			;;
		4|04) 	read -p $'Name the VM you want to start: ' val; virsh start $val && startmenu ;;
		5|05) 	read -p $'Name the VM you want to shutdown: ' val; virsh destroy $val && startmenu ;;


		11) 	sudo apt-get update
			sudo apt-get dist-upgrade -y
			sudo apt-get autoremove -y
			sudo apt-get -y install gcc make linux-headers-$(uname -r) dkms
			sudo apt-get -y install virtualbox virtualbox-ext-pack 		
			startmenu;;
		12) 	virtualbox &
			startmenu ;;
		13) 	VBoxManage list vms | tee VMs.txt; read -p $'Press enter to continue.' val; startmenu ;;
		14) 	read -p $'Name the VM you want to start: ' val; VBoxManage startvm "$val" --type headless && startmenu ;;
		15) 	read -p $'Name the VM you want to shutdown: ' val; VBoxManage controlvm "$val" poweroff --type headless && startmenu ;;

		50) 	FILE="temp/metasploitable-linux-2.0.0.zip"
			FOLDER="Metasploitable2-Linux"
			VMNAME="Metasploitable"
			if [ ! -f $FILE ]; then
			   	mkdir temp; wget -P temp https://download.vulnhub.com/metasploitable/metasploitable-linux-2.0.0.zip
				unzip -d temp $FILE
			else
			   	echo "File $FILE exist."
			fi
			buildvm
			startmenu
			;;
		52)	FILE="temp/IMF.ova"
			FOLDER="IMF"
			VMNAME="IMF-disk1"
			if [ ! -f $FILE ]; then
			   	mkdir temp; mkdir temp/$FOLDER; wget -P temp https://download.vulnhub.com/imf/IMF.ova
				tar -C temp/IMF -xvf $FILE
			else
			   	echo "File $FILE exist."
			fi
			buildvm
			startmenu
			;;

		53)	FILE="temp/necromancer.ova"
			FOLDER="Necromancer"
			VMNAME="necromancer-disk1"
			if [ ! -f $FILE ]; then
			   	mkdir temp; mkdir temp/$FOLDER; wget -P temp https://download.vulnhub.com/necromancer/necromancer.ova
				tar -C temp/$FOLDER -xvf $FILE
			else
			   	echo "File $FILE exist."
			fi
			buildvm
			startmenu
			;;
		54)	FILE="temp/mrRobot.ova"
			FOLDER="MrRobot"
			VMNAME="mrRobot-disk1"
			if [ ! -f $FILE ]; then
			   	mkdir temp; mkdir temp/$FOLDER; wget -P temp https://download.vulnhub.com/mrrobot/mrRobot.ova
				tar -C temp/$FOLDER -xvf $FILE
			else
			   	echo "File $FILE exist."
			fi
			buildvm
			startmenu
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


buildvm() {
	read -p $'  Set up for ONLY KVM (1) or VirtualBox (2): \e[37;1m' vmoption
	case $vmoption in
	1|01)	makekvm $FOLDER $VMNAME && virt-manager ;;
	2|02)	makevb $FOLDER $VMNAME && virtualbox ;;
	*)
	;;
	esac
}

makekvm() {
	mkdir ~/VMs
	VFILE="~/VMs/Metasploitable.qcow2"
	if [ ! -f $VFILE ]; then
		printf "Building KMV qcow2 disk\n"
		ls temp/$1/
	   	qemu-img convert -c -O qcow2 temp/$1/$2.vmdk ~/VMs/$2.qcow2 
	else
	   	echo "File $VFILE exist."
	fi
	virt-install --name=$1 --vcpus=1 --memory=1024 --disk ~/VMs/$2.qcow2,size=8 --os-type linux --os-variant generic --graphics spice,listen=127.0.0.1 --console pty,target_type=serial --import 
# virt-install --name=Metasploitable2-Linux --vcpus=1 --memory=512 --disk ~/VMs/Metasploitable.qcow2,size=8 --os-type linux --os-variant generic --network bridge=virbr0 --graphics spice,listen=127.0.0.1 --console pty,target_type=serial --virt-type=qemu --import
}

makevb() {
	mkdir ~/VirtualBox\ VMs/$1
	printf "Building VirtualBox disk\n"
	cp temp/$1/$2.vmdk ~/VirtualBox\ VMs/$1
	cd ~/VirtualBox\ VMs
	VBoxManage createvm --name $1 --ostype Linux --register
	VBoxManage modifyvm $1 --memory 512
	modifyvm $1 --vtxvpid off
	VBoxManage storagectl $1 --name "IDE Controller" --add ide --controller PIIX4
	VBoxManage storageattach $1 --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium ~/VirtualBox\ VMs/$1/$2.vmdk
	VBoxManage startvm $1
}


stop() {
# 	Cleaning up your mess
	printf "\nCleaning up\n"
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


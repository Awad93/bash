#!/bin/bash

#This script do a ping scan in a network

#Main checks if there is arguments and prints help if there isn't
main(){
	if [ $# -lt 1 ];then
		get_help
	else
		check_ip_format $@
		ping_scan $list
	fi
}

#This function checks if the argument given matches IP address format (x.x.x.x/x) x=number
check_ip_format(){
	if [[ $1 =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}/[0-9]{1,2} ]];then
		ip=$1
		check_ip
	else
		echo "The argument is not IP address"
		get_help
	fi
}

#This function checks the argument is in the range of ip addresses or not
#Example: 300.1.1.1/24, 300 is not in the range of ip addresses
check_ip(){
	part1=$(echo $ip | cut -d'.' -f1)			#$part1 = first byte in IP address
	part2=$(echo $ip | cut -d'.' -f2)			#$part2 = second byte in IP address
	part3=$(echo $ip | cut -d'.' -f3)			#$part3 = third byte in IP address
	part4=$(echo $ip | cut -d'.' -f4 | cut -d'/' -f1)	#$part4 = fourth byte in IP address
	mask=$(echo $ip | cut -d'/' -f2)			#$mask = netmask
	
	if [ $part1 -gt 0 -a $part1 -lt 224 ] &&
	   [ $part2 -ge 0 -a $part2 -le 255 ] && 
	   [ $part3 -ge 0 -a $part3 -le 255 ] &&
	   [ $part4 -ge 0 -a $part4 -le 255 ] &&
	   [ $mask -eq 8 -o $mask -eq 16 -o $mask -eq 24 ];then
		create_list
	else
		echo "Not valid IP"
		get_help
	fi
}

#This function will create a list of ip addresses depending on the netmask
create_list(){
	list=()
	case $mask in
	8) list=($part1.{0..255}.{0..255}.{0..255});;
	16) list=($part1.$part2.{0..255}.{0..255});;
	24) list=($part1.$part2.$part3.{0..255});;
	*) echo "Wrong netmask"
	   get_help;;
	esac
	
	unset list[0]			#Remove network ip
	unset list[${#list[*]}]		#Remove broadcast ip
}

#This function will ping every address in the list
ping_scan(){
	for target in ${list[*]};do
		ping_return=$(ping -c1 -w1 $target)
		parse_ping_output $target $ping_return
	done
}

#This function will format every ping output and decide if the host is up or down
parse_ping_output(){
	packet_loss=$(echo $ping_return | grep -E -o "[0-9]{1,3}% packet loss" | cut -d' ' -f1)
	if [ "$packet_loss" == "100%" ];then
		echo "$target is down"
	else
		echo "$target is up"
	fi
}

#HELP Message
get_help(){
	echo "USAGE: $0 {<IP Address>/<Mask>}
	Example: $0 192.168.10.0/24"
}

main $@





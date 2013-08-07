# Steps to make a Pi into a RoboRouter

Neccessary Hardware:
1. Pi
2. WiFi Dongle (to connect to the robot)
3. Ethernet Cable (to connect to your home network)

Note: You need one RoboRouter per Robot. Each robot is making it's own wifi network, and it is not possible to switch wifi networks fast enough to have a concurrent communication with robots on different networks.

## 1. Define networks

Copy over the file /etc/wpa_supplicant/wpa_roam.conf

### To add a new network

Add the following template to wpa_roam.conf

	network={
        ssid="<NETWORK_SSID>"
        key_mgmt=NONE
        id_str="<UNIQUE_ID>"
	}

replace `<NETWORK_SSID>` with the network id (SSID) of the robot and replace `<UNIQUE_ID>` with an identification string of your choice. This string will be used to reference the robot in the interfaces definition and should be unique.

Use 

	$ iwlist wlan0 scan

to get the network information. If it says Mode:Ad-Hoc, the robot is using an AdHoc network and you have to add 

	mode=1
	frequency=<FREQUENCY>

to the above network definition template. Replace `<FREQUENCY>` with the frequency specified in the iwlist scan result.

## 2. Setup the network interfaces

Copy over the file /etc/network/interfaces

### To add a new robot

1. We need to know the IP address of the robot and the ports on which the robot communicates. If you have that ready, go to step 2, otherwise do the following:

Use nmap to check the network for hosts and scan thoses hosts for open ports:

eg. if the robot is on the subnet 192.168.1

	$ nmap -n 192.168.1.0/24 -e wlan0

which gives a result of the format:

	Nmap scan report for 192.168.1.100
	Host is up (0.037s latency).
	Not shown: 999 closed ports
	PORT   STATE SERVICE
	80/tcp open  http

2. If the robot has a different subnet than your home network, eg. your robot is on the subnet 192.168.0 and your home network on 192.168.1, add the following template to the interfaces file:

	iface <UNIQUE_ID> inet dhcp
	  # forward all packages coming in on the given port to the robot's
	  # ip address and port. the two <PORT_NR> can be the same or different.
	  # add one entry per port that the robot uses
	  up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport <PORT_NR> -j DNAT --to-destination <ROBOT_IP>:<PORT_NR>

replace:
`<UNIQUE_ID>` with the identification string defined earlier
`<ROBOT_IP>` with the ip of the robot
`<PORT_NR>` with the port number that the robot uses

3. If the robot has the same subnet, add this part to the above template;

	  # this will make all packages with the given firewall mark to
	  # go through the wlan0 interface
	  up ip route flush table <TABLE_ID>
	  up ip rule add fwmark <FWMARK_ID> table <TABLE_ID>
	  up ip route add default dev wlan0 table <TABLE_ID>
	  up ip route flush cache
	  #up sysctl net.ipv4.conf.wlan0.rp_filter=0
	  
	  # set the firewall mark for all packages coming in on the given port
	  # add one entry per port that the robot uses
	  up iptables -A PREROUTING -i eth0 -t mangle -p tcp --dport <PORT_NR> -j MARK --set-mark <TABLE_ID>

replace:
`<TABLE_ID>` with a number of your choice
`<FWMARK_ID>` with a number of your choice, can be the same or different than the `<TABLE_ID>`
`<PORT_NR>` with the same port number used for the entry in the above template

## Manage RoboRouter to connect to robots

Only robot can be connected at a time. To make the pi switch from one robot to another, use the command line tool `wpa_cli`

1. List defined networks

	$ wpa_cli list_networks

e.g.
	$ wpa_cli list_networks
	Selected interface 'wlan0'
	network id / ssid / bssid / flags
	0	Rover_00E04C07F81A	any	
	1	AC13_00E04C06E710	any	
	2	HC00FF83	any	

2. Select network

	$ wpa_cli select_network <NETWORK_ID>

e.g.
	$ wpa_cli select_network 1
	Selected interface 'wlan0'
	OK

3. Get network status

	$ wpa_cli status

e.g.
	$ wpa_cli status
	Selected interface 'wlan0'
	bssid=80:07:a2:00:ff:83
	ssid=HC00FF83
	id=2
	id_str=spytank
	mode=station
	pairwise_cipher=NONE
	group_cipher=NONE
	key_mgmt=NONE
	wpa_state=COMPLETED
	ip_address=10.10.1.100
	address=24:3c:20:08:9d:48

## Find the RoboRouter on the Network

In order to use the RoboRouter we need to know it's ip address. If you don't want to put a screen on the Pi, or check the router, you can either set a static ip address or use the following easy setup:

1. install xinetd

	$ sudo apt-get install xinetd

2. open the files /etc/xinetd.d/time and /etc/xinet.d/echo and change to disable = false

3. now you can use nmap on another computer to scan the network and check which hosts have the ports 7 and 37 open. This will be the robot router.

e.g.
	$ nmap -Pn -p7,37 <IP_ADDRESS>/24 -oG - | awk '/open/{print "  " $2}

replace `<IP_ADDRESS>` with the ip address of the computer.
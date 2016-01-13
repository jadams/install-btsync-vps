#!/bin/sh

check_for_root() {
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root" 1>&2
		exit 1
	fi
}

display_usage() {
	echo -e "\nUsage:\n$0 [--uninstall] \n" 	
}

download() {
	echo "Downloading..."
	wget --quiet -O - https://download-cdn.getsync.com/stable/linux-x64/BitTorrent-Sync_x64.tar.gz | tar xz -C /tmp 
}

install_user() {
	echo "Adding btsync user..."
	useradd -r -s /bin/sh -d /var/lib/btsync btsync
	mkdir -p /var/lib/btsync
	chown -R btsync:btsync /var/lib/btsync
	mkdir -p /var/run/btsync
	chown -R btsync:btsync /var/run/btsync
}

install_files() {
	echo "Installing files..."
	cp /tmp/btsync /usr/bin/btsync
	btsync --dump-sample-config | sed 's:/home/user/\.sync:/var/lib/btsync:' | sed 's:\/\/ "pid_file":  "pid_file":' | sed 's:\/\/ "storage_path":  "storage_path":' | sed 's:0\.0\.0\.0:127\.0\.0\.1:' > /etc/btsync.conf
	chown btsync:btsync /etc/btsync.conf
	chmod 600 /etc/btsync.conf
}

install_service() {
	echo "Installing service..."
	echo "[Unit]
	Description=Bittorent Sync service
	After=network.target
	 
	[Service]
	Type=forking
	User=btsync
	Group=btsync
	ExecStart=/usr/bin/btsync --config /etc/btsync.conf
	Restart=on-abort
	
	[Install]
	WantedBy=multi-user.target" > /lib/systemd/system/btsync.service
}

uninstall() {
	echo "Stopping service"
	systemctl stop btsync.service
	echo "Disabling service"
	systemctl disable btsync.service
	echo "Removing btsync user"
	userdel -rf btsync
	echo "Removing btsync group"
	groupdel btsync
	echo "Removing files"
	rm -f /lib/systemd/system/btsync.service
	rm -f /etc/btsync.conf
	rm -rf /var/run/btsync
	rm -rf /var/lib/btsync
	rm -f /usr/bin/btsync
}

install() {
	download
	install_user
	install_files
	install_service
}

check_for_root
if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then 
	display_usage
	exit 0
elif [[ $1 == "--uninstall" ]]; then
	uninstall
	exit 0
else
	install
	exit 0
fi

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
	echo -n "Downloading..."
	wget --quiet -O - https://download-cdn.getsync.com/stable/linux-x64/BitTorrent-Sync_x64.tar.gz | tar xz -C /tmp 
	echo "[OK]"
}

install_user() {
	echo -n "Adding btsync user"
	useradd -r -s /bin/sh -d /var/lib/btsync btsync
	echo -n "."
	mkdir -p /var/lib/btsync
	echo -n "."
	chown -R btsync:btsync /var/lib/btsync
	echo -n "."
	mkdir -p /var/run/btsync
	echo -n "."
	chown -R btsync:btsync /var/run/btsync
	echo "[OK]"
}

install_files() {
	echo -n "Installing files"
	cp /tmp/btsync /usr/bin/btsync
	echo -n "."
	btsync --dump-sample-config | sed 's:/home/user/\.sync:/var/lib/btsync:' | sed 's:\/\/ "pid_file":  "pid_file":' | sed 's:\/\/ "storage_path":  "storage_path":' | sed 's:0\.0\.0\.0:127\.0\.0\.1:' > /etc/btsync.conf
	echo -n "."
	chown btsync:btsync /etc/btsync.conf
	echo -n "."
	chmod 600 /etc/btsync.conf
	echo "[OK]"
}

install_service() {
	echo -n "Installing service..."
	echo -n "[Unit]
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
	echo "[OK]"
}

uninstall() {
	echo -n "Stopping service..."
	systemctl stop btsync.service
	echo "[OK]"
	echo -n "Disabling service..."
	systemctl disable btsync.service
	echo "[OK]"
	echo -n "Removing btsync user..."
	userdel -rf btsync
	echo "[OK]"
	echo -n "Removing btsync group..."
	groupdel btsync
	echo "[OK]"
	echo -n "Removing files"
	rm -f /lib/systemd/system/btsync.service
	echo -n "."
	rm -f /etc/btsync.conf
	echo -n "."
	rm -rf /var/run/btsync
	echo -n "."
	rm -rf /var/lib/btsync
	echo -n "."
	rm -f /usr/bin/btsync
	echo "[OK]"
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

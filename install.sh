#!/bin/sh
wget -O - https://download-cdn.getsync.com/stable/linux-x64/BitTorrent-Sync_x64.tar.gz | tar xzv -C /tmp
cp /tmp/btsync /usr/bin/btsync
useradd -r -s /bin/sh -d /var/lib/btsync btsync
mkdir -p /var/lib/btsync
chown -R btsync:btsync /var/lib/btsync
mkdir -p /var/run/btsync
chown -R btsync:btsync /var/run/btsync
btsync --dump-sample-config | sed 's:/home/user/\.sync:/var/lib/btsync:' | sed 's:\/\/ "pid_file":  "pid_file":' | sed 's:\/\/ "storage_path":  "storage_path":' | sed 's:0\.0\.0\.0:127\.0\.0\.1:' > /etc/btsync.conf
chown btsync:btsync /etc/btsync.conf
chmod 600 /etc/btsync.conf
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
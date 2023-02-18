#!/bin/sh
#script to prepare ubuntu desktop vm for cloning
apt-get update
apt-get upgrade -y

#open ssh
apt-get install -y open-vm-tools openssh-server
cat /dev/null > /var/log/wtmp 
cat /dev/null > /var/log/lastlog 
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -f /etc/ssh/ssh_host*
rm -f /etc/udev/rules.d/70-persistent-net.rules
cat <<EOL | sudo tee /etc/rc.local
#!/bin/sh -e
test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL
# assumption is that the host is already named
#echo ubuntu > /etc/hostname
apt-get clean
history -c
history -w
chmod +x /etc/rc.local
systemctl stop apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.timer
systemctl stop apt-daily.timer
systemctl disable apt-daily.timer
sudo apt autoremove -y
#truncate the machine id to avoid duplicate dhcp
#OM Fixes
echo -n > /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
echo "remove git repo and then issue a shutdown - h now"

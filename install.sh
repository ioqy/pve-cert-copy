#!/bin/sh

if [ "$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi

cat << EOF > /usr/local/bin/pve-cert-copy.sh
#!/bin/sh
if [ "\$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi
NODE=\$(hostname)
cp /etc/pve/nodes/\${NODE}/pveproxy-ssl.pem /etc/proxmox-backup/proxy.pem
cp /etc/pve/nodes/\${NODE}/pveproxy-ssl.key /etc/proxmox-backup/proxy.key
chmod 640 /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
chgrp backup /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
systemctl reload proxmox-backup-proxy.service
EOF

cat << EOF > /etc/systemd/system/pve-cert-copy.service
[Unit]
Description=Copy PVE certificate for proxmox backup server
After=pve-daily-update.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/pve-cert-copy.sh
[Install]
WantedBy=pve-daily-update.service
EOF

cat << EOF > /usr/local/bin/uninstall-pve-cert-copy.sh
#!/bin/sh
if [ "\$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi
systemctl disable pve-cert-copy.service
rm /etc/systemd/system/pve-cert-copy.service
systemctl daemon-reload 2>/dev/null
rm /usr/local/bin/pve-cert-copy.sh
rm /usr/local/bin/uninstall-pve-cert-copy.sh
EOF

chmod +x /usr/local/bin/pve-cert-copy.sh
chmod +x /usr/local/bin/uninstall-pve-cert-copy.sh

systemctl daemon-reload
systemctl enable --now pve-cert-copy.service

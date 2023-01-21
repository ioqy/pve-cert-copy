#!/bin/sh

if [ "$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi

if [ -e "/usr/local/bin/uninstall-pve-cert-copy.sh" ]; then
  /usr/local/bin/uninstall-pve-cert-copy.sh
fi

cat << EOF > /etc/systemd/system/pve-cert-copy.service
[Unit]
Description=Copy PVE certificate for proxmox backup server
After=pve-daily-update.service
[Service]
Type=oneshot
ExecStart=/usr/bin/cp /etc/pve/nodes/$(hostname)/pveproxy-ssl.pem /etc/proxmox-backup/proxy.pem
ExecStart=/usr/bin/cp /etc/pve/nodes/$(hostname)/pveproxy-ssl.key /etc/proxmox-backup/proxy.key
ExecStart=/usr/bin/chmod 640 /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
ExecStart=/usr/bin/chgrp backup /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
ExecStart=/usr/bin/systemctl reload proxmox-backup-proxy.service
[Install]
WantedBy=pveproxy.service
EOF

cat << EOF > /etc/systemd/system/pve-cert-copy.path
[Unit]
Description=Copy PVE certificate for proxmox backup server
[Path]
PathChanged=/etc/pve/nodes/pm/pve-ssl.pem
Unit=pve-cert-copy.service
[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /usr/local/bin/uninstall-pve-cert-copy.sh
#!/bin/sh
if [ "\$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi
systemctl disable pve-cert-copy.service
systemctl disable --now pve-cert-copy.path
systemctl daemon-reload 2>/dev/null
rm /usr/local/bin/uninstall-pve-cert-copy.sh
EOF

systemctl daemon-reload
systemctl enable --now pve-cert-copy.path
# Run once after installation
systemctl enable --now pve-cert-copy.service

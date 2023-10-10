#!/usr/bin/env sh

if [ "$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi

# Uninstall old version
[ -e /usr/local/bin/uninstall-pve-cert-copy.sh ] && /usr/local/bin/uninstall-pve-cert-copy.sh

mkdir --parents /etc/systemd/system/pveproxy.service.d

cat << EOF > /usr/local/bin/pve-cert-copy.sh
#!/usr/bin/env sh
[ ! -e /etc/proxmox-backup ] && exit 0
cp --preserve=timestamps /etc/pve/local/pveproxy-ssl.key /etc/proxmox-backup/proxy.key
cp --preserve=timestamps /etc/pve/local/pveproxy-ssl.pem /etc/proxmox-backup/proxy.pem
chmod 640 /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
chgrp backup /etc/proxmox-backup/proxy.key /etc/proxmox-backup/proxy.pem
systemctl reload proxmox-backup-proxy.service
EOF

cat << EOF > /etc/systemd/system/pveproxy.service.d/pve-cert-copy-override.conf
[Service]
ExecReload=-/usr/local/bin/pve-cert-copy.sh
ExecStartPost=-/usr/local/bin/pve-cert-copy.sh
EOF

cat << EOF > /usr/local/bin/uninstall-pve-cert-copy.sh
#!/usr/bin/env sh
if [ "\$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi
rm /etc/systemd/system/pveproxy.service.d/pve-cert-copy-override.conf
[ \$(ls -A /etc/systemd/system/pveproxy.service.d) ] || rmdir /etc/systemd/system/pveproxy.service.d
systemctl daemon-reload 2>/dev/null
rm /usr/local/bin/pve-cert-copy.sh
rm /usr/local/bin/uninstall-pve-cert-copy.sh
EOF

chmod u+x /usr/local/bin/uninstall-pve-cert-copy.sh
chmod u+x /usr/local/bin/pve-cert-copy.sh

systemctl daemon-reload
# Run once after installation
/usr/local/bin/pve-cert-copy.sh

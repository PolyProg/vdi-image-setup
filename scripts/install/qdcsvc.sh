#!/bin/sh
# Install QDCSVC, the Quest Data Collector Service

# Install a systemd service
cat > '/etc/systemd/system/qdcsvc.service' << EOF
[Unit]
Description = QDCSVC systemd service

[Service]
Type=forking
ExecStart=/opt/VDEFORLINUX/VirtualDesktopExtension/x64/qdcsvc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable qdcsvc.service

# Install the config file for QDCSVC (with placeholders)
cp '/opt/VDEFORLINUX/Provisioning/qdcsvc.conf' '/etc/qdcsvc.conf'

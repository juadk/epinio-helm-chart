#!/bin/bash

set -e

curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/main/scripts/install.sh | bash
gofish init
gofish install chartmuseum

helm plugin install https://github.com/chartmuseum/helm-push.git

cat <<EOF | sudo tee /etc/systemd/system/chartmuseum.service
[Unit]
Description=Helm Chartmuseum
Documentation=https://chartmuseum.com/

[Service]
ExecStart=/usr/local/bin/chartmuseum \\
 --debug \\
 --port=8090 \\
 --storage="local" \\
 --storage-local-rootdir="/home/${USER}/chartstorage/"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start chartmuseum

sleep 5

helm repo add chartmuseum http://localhost:8090

cd chart/
helm cm-push --version "0.1.0" epinio-installer/ chartmuseum
helm cm-push --version "0.1.0" epinio/ chartmuseum
helm cm-push --version "0.1.0" container-registry/ chartmuseum

sed -i -e 's|containerRegistryChart:.*|containerRegistryChart: "http://localhost:8090/container-registry-0.1.0.tgz"|'\
       -e 's|epinioChart:.*|epinioChart: "http://localhost:8090/epinio-0.1.0.tgz"|'\
       ../chart/epinio-installer/values.yaml

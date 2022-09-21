#!/bin/bash

# Install k3s and dependencies
# Writtin by Coen Stam.
# github@theautomation.nl
#

manifest_location="/var/lib/rancher/k3s/server/manifests/"
github_repo="https://github.com/theautomation/kubernetes-gitops.git"

# Update and install packages
sudo apt update \
&& sudo apt upgrade -y \
&& sudo apt install -y curl wget unzip git

# ISCSI
echo -e "\nInstalling ISCSI...\n"
sudo apt-get install -y open-iscsi lsscsi sg3-utils multipath-tools scsitools

sudo tee /etc/multipath.conf <<-'EOF'
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF

sudo systemctl enable multipath-tools.service
sudo service multipath-tools restart
sudo systemctl enable open-iscsi.service
sudo service open-iscsi start

# QEMU guest agent
echo -e "\nInstalling QEMU guest agent...\n" &&
    sudo apt-get install qemu-guest-agent -y

if [[ $HOSTNAME =~ master ]]; then
    # Setup masters
    if [[ $HOSTNAME = "k3s-master-01" ]]; then

        # Create dir for init manifests
        sudo mkdir -p ${manifest_location}

        # Git clone
        git clone ${github_repo}

        # Create sealedsecret custom certificate in init repo folder
        echo "Enter tls.key base64 encoded string for Bitnami Sealed Secret:"
        read -r tls_key

        sudo cat <<EOF >./kubernetes-gitops/deploy/k8s/sealed-secret-customkeys-2.yaml
        ---
        kind: Secret
        apiVersion: v1
        type: kubernetes.io/tls
        metadata:
        name: sealed-secret-customkeys-2
        namespace: kube-system
        labels:
            sealedsecrets.bitnami.com/sealed-secrets-key: active
        data:
        tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZRVENDQXltZ0F3SUJBZ0lVU2lCYXdFaFR0Vms1RnQyd3diZWd3VGhxOVNNd0RRWUpLb1pJaHZjTkFRRUwKQlFBd01ERVdNQlFHQTFVRUF3d05jMlZoYkdWa0xYTmxZM0psZERFV01CUUdBMVVFQ2d3TmMyVmhiR1ZrTFhObApZM0psZERBZUZ3MHlNakEyTVRreE1ETXhNRFJhRncwek1qQTJNVFl4TURNeE1EUmFNREF4RmpBVUJnTlZCQU1NCkRYTmxZV3hsWkMxelpXTnlaWFF4RmpBVUJnTlZCQW9NRFhObFlXeGxaQzF6WldOeVpYUXdnZ0lpTUEwR0NTcUcKU0liM0RRRUJBUVVBQTRJQ0R3QXdnZ0lLQW9JQ0FRRHkrTkRrOXNPWCt3Yzl1YXlIbkJGdS9OS2Z6em0vdUJ2VgppODdLMUMxMnl2V01TVW05b0NzTDFwQzlCaUN6eXZVdDd6SG9jczZLaWl1RmFQQ3c5SHF2RTA2bUxKblhqL0dZCjNUQktVM1NkVTVPUHZmZVZNYW84clpUMGNhVXFXTHE1ckoxTE40QTNlRWUxSTlrVUQ4WmhRdmJBOTVIR3p4U1AKWVFUakcySkZKcFJpUkpPOG9aT3VPVTlsTTMrZ0Zsc2ZuSnB0K1NYbWpaYXlVYVczZndHMmR5OEpCREtrREhzQgpaR0tRWmk3L2NzWjZZcnhEY0hLZktNcTlOazJvYzBYK1hIYndoV2N4YjBKbm94MWhiVk56M3FsbisxeVUrM2t6ClVSVmhvTGpnazFoT3A1dVdzQXVhWVF4U3hkd3QwVDVSZXRVVHB5NlRocXdhVy81aXkvK3dlWllIWlZ6aTRJSDEKdVcxNTVqTzhzVGR4WXZCVUZQdStNWTNCK1JFQTlXejRzeGZMRXJyd1JKVi9UTkFGa1JkZ0huaEhtM05jc1RtVwpxM2U5c1lueVFBcml1WEhhUDZaRU1lWmVWWGY3UUZmM3lVU2pRL1dCTWRUOFJEQmRFdzRWUHFIc1cwQjQ3WkRQCmJabkhGOUtGem5CTHN6V0VLWVAyampMNWJxY2hDcFlIZGdhb2Q3Q3ZuNW1aai92N0M3QkNpdzZWVEtIQUhPbm8KR1FmYU1hV2dTZGMxNW8wR3JucUd0cTFGZm5GcW9oUlZMdjJOaXcyOEE0U25ZUEQxYTJiUWYxVk9OTHV5Nm0rKwpyUlltWEdidDBOZUEyWXVUL1J3ZThLTEkvc29SYmtGejZWK0UyWXVMSTZLaE44bVlxbE16QWlNS3h4VWRtclZuCnFCdGEvbkpsMFFJREFRQUJvMU13VVRBZEJnTlZIUTRFRmdRVVVGQytjRkNEZzRwQVpmb0ZGbDhXODhjWFdIRXcKSHdZRFZSMGpCQmd3Rm9BVVVGQytjRkNEZzRwQVpmb0ZGbDhXODhjWFdIRXdEd1lEVlIwVEFRSC9CQVV3QXdFQgovekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBZ0VBeitVQXdxY1hwaGhkM0FKU0RLYnRTa29WMXhEUlBqOEhhdlNZCjlDOEZ0cUpVZEdLN0E5NDZNUE96bHMxSlAyTE5pQnN4b1FTa25YeU4wZEhVRndvNVZhNW4rd3pScmFsQzlqczAKM1lQVDZSSjBmQk8yRUtXbWNuZ2Ewd2lmYVJBVXhHWmY4dnY1b3RHLzY0UzhhMlFCU3VJOEl1a1NpelB1ZGtRTQoyWGRDK25FeGNGKzVKZVRrVEtFeDcxeGl6Q3FUOG1PdlRuMlloZW9qRVJON01PZzNxRkR0bWg0OTRoaEZDYzRoCkxwc3RYR2VDbHFPVEJldzh1WjRuZ0hLQ3Rqc3dBdXczWXZnRU8yNWFIcDJHTkpCek5aYTYzSDZZY2xuL1JFcnUKeklHUTBWME12RUJudldlWXRheCtoV2QzbmRsYk9pS0doSGNIQlBxNnJkUUFJdkpuaHlzNXBzZVVWTUYyU0tLYQpDT1NIczVyenJVbzNONGhpU1gzZUNHNG9TUkp4cEYrQVlRUEJQWXhIVDBYa2dEb212RGJ6WUdvbWx0RkFqdkFmCktXc0pYUk1mcVczNGdPV3QzZlZFaFVUZVZGc0t5YXFDbnkxVDFKUVJ3QmdzSmNKVjhYcDBaK0JOc1V2Y1pDY2EKSlVjSzlEbGUrUk83MktxdlZaeHYzaUc3UW40RW5tWHFuZUpTYXRrbXY4ejJiK29EVFNBNUppMXFSb2VuK216SgovU2NYR2hJaHBIS1ZBczB1Qit5YXc3QkZNQlBibHRlK2N4emVwd3FmdDdhZWtGZTVvcFRrOGUxTXBrcXhCNmF3Cm1XdnRUUFBZVlk3bjVGaEdMUHJZUllENlJ2SzU0NmR1L0lERUlMcUdxRkVkWU5TQ1hMREFpbllKbE43bytTZ1YKa1RTb0RVQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
        tls.key: ${tls_key} 
EOF

        # Copy init manifests to init folder
        sudo cp -rv ./kubernetes-gitops/deploy/k8s/* ${manifest_location}

        echo -e "\nInstalling k3s master and initializing the cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --tls-san ${k3s_vipip} --no-deploy servicelb --cluster-init
    else
        echo -e "\nInstalling k3s master and joining to cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --tls-san ${k3s_vipip} --no-deploy servicelb --server=https://${k3s_cluster_init_ip}:6443
    fi
    sleep 10 && echo -e "\nInstalling k3s on $HOSTNAME done.\n" &&
        kubectl get nodes -o wide
else
    # Setup workers
    echo -e "\nInstalling k3s workers and joining to cluster...\n" &&
        curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_cluster_init_ip}:6443 K3S_TOKEN=${k3s_token} sh -
fi

# Cleanup
sudo rm -r ./kubernetes-gitops

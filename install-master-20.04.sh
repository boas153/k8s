#!/bin/bash
set -e

echo "[1/10] 시스템 업데이트 중..."
sudo apt update && sudo apt upgrade -y

echo "[2/10] 필수 패키지 설치 중..."
sudo apt install -y apt-transport-https ca-certificates curl gpg

echo "[3/10] containerd 설치 및 설정 중..."
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[4/10] Swap 끄는 중..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[5/10] 네트워크 커널 모듈 설정 중..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter

echo "[6/10] 네트워크 커널 파라미터 설정 중..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# ip_forward 강제 적용 (최종 방어)
echo "[+] ip_forward 즉시 적용 중..."
sudo sysctl -w net.ipv4.ip_forward=1

echo "[7/10] Kubernetes 저장소 추가 중..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

echo "[8/10] Kubernetes 설치 중..."
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[9/10] Kubernetes 마스터 초기화 중..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "[10/10] kubeconfig 세팅 중..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[+] Flannel 네트워크 설치 중..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "🎯 클러스터 초기화 완료!"
echo ""
echo "🎯 슬레이브 노드 조인 명령어 (복사해서 워커에 입력):"
kubeadm token create --print-join-command

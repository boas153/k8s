# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 필요한 패키지 설치
sudo apt install -y apt-transport-https ca-certificates curl

# 호스트네임 설정 (선택)
sudo hostnamectl set-hostname worker-node

# Docker GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker 저장소 추가
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Docker 활성화 및 부팅시 자동 시작
sudo systemctl enable docker
sudo systemctl start docker

# Kubernetes GPG 키 추가
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Kubernetes 저장소 추가
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

# 패키지 설치
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# kubelet 잠금 (자동 업데이트 방지)
sudo apt-mark hold kubelet kubeadm kubectl

# swap 끄기 (필수)
sudo swapoff -a

# /etc/fstab에서 swap 자동 마운트 제거
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Kubernetes 커널 모듈 적용
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter

# 커널 파라미터 세팅
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system


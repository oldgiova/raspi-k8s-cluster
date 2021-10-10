# raspi-k8s-cluster
Raspberry Pi K8s Cluster

## Setup
1. Flash Raspbian Buster on your RPis
1. Setup fixed network connection and fixed hosts on every node
1. Set every IP/Host in `/etc/hosts` of your Load Balancer Raspberry
1. Create your `config.env` based on [config.env.example](config.env.example) file
1. Set your Control Plane hosts and Worker hosts (comma separated)



Here's a more compact yet informative version of your EKS creation guide in Markdown format. It keeps essential explanations while being concise:

---

# Create EKS Cluster with `eksctl`

This guide shows how to create an [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) cluster using [`eksctl`](https://eksctl.io/).

---

## Prerequisites

Ensure the following are installed and configured:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* [`eksctl`](https://eksctl.io/)
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
* AWS credentials with EKS & EC2 permissions

---

## Create EKS Cluster (Control Plane Only)

```bash
eksctl create cluster \
  --name=simple-eks-cluster \
  --region=us-east-1 \
  --zones=us-east-1a,us-east-1b \
  --without-nodegroup
```

Creates the control plane and networking. No nodes yet.

---

## Associate IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster simple-eks-cluster \
  --approve
```

Enables IAM roles for Kubernetes service accounts.

---

## Create EC2 Key Pair (for SSH)

```bash
aws ec2 create-key-pair \
  --key-name MyKeyPair \
  --query 'KeyMaterial' \
  --output text > MyKeyPair.pem
chmod 400 MyKeyPair.pem
```

Saves the private key for SSH access to worker nodes.

---

## Create Managed Node Group

```bash
eksctl create nodegroup \
  --cluster=simple-eks-cluster \
  --region=us-east-1 \
  --name=simple-eks-cluster-ng-public1 \
  --node-type=t3.medium \
  --nodes=2 \
  --nodes-min=2 \
  --nodes-max=4 \
  --node-volume-size=20 \
  --ssh-access \
  --ssh-public-key=MyKeyPair \
  --managed \
  --asg-access \
  --external-dns-access \
  --full-ecr-access \
  --appmesh-access \
  --alb-ingress-access
```

Creates 2–4 auto-scaling managed EC2 nodes with optional service permissions.

---

## Verify

```bash
kubectl get nodes
```

---

## To Delete Cluster

```bash
eksctl delete cluster --name=simple-eks-cluster --region=us-east-1
```

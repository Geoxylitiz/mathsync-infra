# MathSync DevOps Infrastructure

This repository contains the Infrastructure as Code (IaC) configuration for provisioning the AWS infrastructure and Kubernetes cluster for the **MathSync** platform using **Terraform**.

## Architecture Overview

The infrastructure is split into two logical layers:
1. **Cluster Layer (`cluster/`)**: Provisions the AWS core networking components, IAM roles, and the EKS Cluster.
2. **Addons Layer (`addons/`)**: Deploys Kubernetes core software/addons (ArgoCD, Prometheus, Grafana) via Helm provider, sourcing EKS cluster details from the cluster layer's state.

```mermaid
graph TD
    subgraph AWS VPC (10.0.0.0/16)
        subgraph Public Subnets
            IGW[Internet Gateway]
            NAT[NAT Gateway]
            ALB[Application Load Balancer]
        end

        subgraph Private Subnets
            EKS[EKS Cluster v1.32]
            NG[Managed Node Groups: t3.small]
        end
    end

    ALB -->|Ingress Traffic| EKS
    NG -->|Internet Egress| NAT
    NAT --> IGW
    
    subgraph EKS Addons
        ArgoCD[ArgoCD GitOps]
        Prom[kube-prometheus-stack]
    end
    EKS --> ArgoCD
    EKS --> Prom
```

---

## Directory Structure

```text
INFRA/
├── cluster/                   # Core AWS & EKS provisioning
│   ├── modules/
│   │   ├── network/           # VPC, subnets, IGW, NAT GW, and routing
│   │   ├── iam/               # IAM roles for EKS Control Plane and worker nodes
│   │   ├── eks/               # AWS EKS cluster configuration (v1.32)
│   │   └── ecr/               # (Placeholder for Container Registry)
│   ├── main.tf                # Roots and connects all modules
│   ├── variables.tf           # Configuration variables (Region, project name, etc.)
│   ├── outputs.tf             # Outputs cluster details for next layer
│   ├── versions.tf            # Terraform and AWS provider versions
│   └── providers.tf           # AWS provider configuration
│
├── addons/                    # Helm releases on EKS (Kubernetes addons)
│   ├── main.tf                # Configures AWS, Kubernetes, and Helm providers
│   ├── k8s-addons.tf          # Installs ArgoCD and Prometheus Stack via Helm
│   ├── variables.tf           # Addon variables
│   └── versions.tf            # Helm, Kubernetes, AWS, and Terraform versions
│
└── environments/              # Space for environment-specific var configurations
    └── dev/                   # Development environment vars (currently empty)
```

---

## Component Details

### 1. Network Module (`cluster/modules/network`)
Provisions a highly-available network topology spanning two Availability Zones (AZs):
- **VPC**: `10.0.0.0/16` CIDR.
- **Public Subnets**: `10.0.1.0/24` and `10.0.2.0/24` (tagged with `"kubernetes.io/role/elb" = "1"` for ingress controllers).
- **Private Subnets**: `10.0.101.0/24` and `10.0.102.0/24` (tagged with `"kubernetes.io/role/internal-elb" = "1"` for internal load balancers).
- **NAT Gateway & EIP**: Deployed in a public subnet to allow outbound-only internet access for resources in private subnets.
- **Route Tables**: Automated mapping of routing to IGW (public) and NAT (private).

### 2. IAM Module (`cluster/modules/iam`)
Follows the principle of least privilege, providing:
- **EKS Cluster Role**: Standard `AmazonEKSClusterPolicy`.
- **Node Group Role**: Policies including `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly`.

### 3. EKS Module (`cluster/modules/eks`)
Uses the official AWS EKS Terraform module (`~> 21.0`):
- **Kubernetes Version**: `1.32`
- **Networking**: Configures EKS Addons `vpc-cni`, `kube-proxy`, and `coredns`.
- **Worker Nodes**: Configures a managed node group named `default` running on `t3.small` instances, scaling dynamically between `2` and `4` nodes (desired: `2`).
- **Access**: Enables public API endpoint access and grants admin permissions to the cluster creator (`enable_cluster_creator_admin_permissions = true`).

### 4. Kubernetes Addons (`addons/`)
Deploys core application layers directly using Terraform's Helm provider:
- **ArgoCD**: Set up in the `argocd` namespace, configured with a service type of `LoadBalancer` for easy ingress dashboard access.
- **Kube-Prometheus-Stack**: Set up in the `monitoring` namespace for full-stack cluster observability. Grafana is configured as a `ClusterIP` service.

---

## Deployment Instructions

### Prerequisites
Make sure you have installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (`>= 1.8.0`)
- [AWS CLI](https://aws.amazon.com/cli/) (configured with administrator credentials)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)

---

### Step 1: Deploy AWS Infrastructure & EKS Cluster
Navigate to the `cluster` directory and initialize Terraform:

```bash
cd cluster
terraform init
```

Review the execution plan:
```bash
terraform plan
```

Apply the changes to provision the VPC, IAM, and EKS Cluster (this will take approximately 10-15 minutes):
```bash
terraform apply -auto-approve
```

---

### Step 2: Configure Local Kubectl
Once the cluster deployment completes, configure your local `kubectl` context to communicate with the newly created cluster. Run:

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name mathsync-cluster
```

Verify that you can communicate with the cluster and check the nodes:
```bash
kubectl get nodes
```

---

### Step 3: Deploy Kubernetes Addons (ArgoCD & Monitoring)
Navigate to the `addons` directory. This module depends on the Terraform state of the `cluster` module to retrieve endpoints and auth tokens.

```bash
cd ../addons
terraform init
terraform apply -auto-approve
```

---

## Accessing the Deployed Addons

### ArgoCD
ArgoCD is configured with a LoadBalancer. 

1. **Retrieve the ArgoCD Server URL**:
   ```bash
   kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
   *Note: It may take a couple of minutes for the LoadBalancer to provision and resolve.*

2. **Retrieve the Initial Admin Password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
   ```

3. **Login**:
   Open the URL in your browser, select username `admin`, and enter the password retrieved above.

---

### Prometheus & Grafana
Grafana is deployed as a `ClusterIP` service. You can access it securely using port-forwarding:

1. **Port Forward Grafana**:
   ```bash
   kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
   ```

2. **Access Grafana Dashboard**:
   Go to `http://localhost:3000` in your web browser.

3. **Retrieve Grafana Credentials**:
   Username: `admin`  
   Retrieve the password:
   ```bash
   kubectl get secret kube-prometheus-stack-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
   ```

---

## Tear Down / Cleanup

To delete the resources and avoid ongoing AWS charges, destroy the modules in **reverse order**:

1. **Destroy Addons**:
   ```bash
   cd addons
   terraform destroy -auto-approve
   ```

2. **Destroy Cluster**:
   ```bash
   cd ../cluster
   terraform destroy -auto-approve
   ```

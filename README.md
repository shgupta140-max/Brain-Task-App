# MindTrack

MindTrack is a containerized static web application deployment project. The compiled frontend is served by Nginx, packaged into a Docker image, pushed to Amazon ECR, and deployed to Amazon EKS behind an AWS Application Load Balancer.

## Repository Layout

```text
app/
	dist/                 Compiled frontend assets
	Dockerfile            Nginx image definition
	nginx.conf            Nginx and SPA routing configuration
	buildspec.yml         AWS CodeBuild build and deployment pipeline
eks-cluster/            Terraform definitions for the AWS/EKS infrastructure
kubedefs/
	namespace.yml         mindtrack namespace
	deployment.yml        MindTrack deployment and pod configuration
	aws-alb-ingress.yml   Service and AWS ALB ingress
```

The repository contains the production frontend output rather than its source code. It therefore does not require `package.json`, `node_modules`, or a frontend build toolchain.

## Architecture

```text
Developer push
			|
			v
AWS CodeBuild -> Docker image -> Amazon ECR
			|
			v
Amazon EKS / mindtrack namespace
			|
		    v
Nginx service on port 3000
			|
			v
AWS Application Load Balancer
            |
            v
GoDaddy DNS: mindtrack -> ALB (CNAME record)
            |
            V
Internet: https://mindtrack.nikboss.xyz
```

The Kubernetes deployment runs two replicas. Nginx uses SPA fallback routing so client-side application routes resolve to `index.html`.

## Prerequisites

- AWS CLI configured with permissions for ECR, EKS, IAM, EC2, and ACM
- Terraform
- Docker
- `kubectl`
- An existing ECR repository and CodeBuild project when using the CI/CD pipeline

The default AWS region is `ap-south-1`. Review the Terraform variables and Kubernetes annotations before deploying to another account or region.

## Run Locally with Docker

Build and run the Nginx image from the repository root:

```bash
docker build -t mindtrack:local ./app
docker run --rm -p 3000:3000 mindtrack:local
```

Open `http://localhost:3000` in a browser. The image copies `app/dist` into Nginx's document root and listens on port `3000`.

## Provision AWS Infrastructure

The Terraform configuration creates the networking, EKS cluster, managed node group, IAM permissions, and cluster add-ons.

```bash
cd eks-cluster
terraform init
terraform plan
terraform apply
```

After the cluster is created, configure `kubectl` using the cluster name and region:

```bash
aws eks update-kubeconfig --name mindtrack-cluster --region ap-south-1
```

## Deploy to Kubernetes Manually

Apply the namespace, deployment, service, and ALB ingress:

```bash
kubectl apply -f kubedefs/namespace.yml
kubectl apply -f kubedefs/deployment.yml
kubectl apply -f kubedefs/aws-alb-ingress.yml
```

Check rollout and ingress status:

```bash
kubectl rollout status deployment/mindtrack-deployment -n mindtrack
kubectl get pods,svc,ingress -n mindtrack
```

The ingress is configured for the host in `kubedefs/aws-alb-ingress.yml` and redirects HTTP traffic to HTTPS. Its ACM certificate ARN and DNS host must be valid for the target AWS account and domain.

## CI/CD with AWS CodeBuild

`app/buildspec.yml` performs the following steps:

1. Authenticates Docker with Amazon ECR.
2. Builds the image from `./app`.
3. Tags the image with `latest` and the first seven characters of the source commit.
4. Pushes both tags to ECR.
5. Updates the EKS deployment to the commit-tagged image.

Configure these CodeBuild environment variables:

| Variable | Description |
| --- | --- |
| `AWS_REGION` | AWS deployment region, for example `ap-south-1` |
| `AWS_ACCOUNT_ID` | AWS account ID that owns the ECR repository |
| `IMAGE_REPO_NAME` | ECR repository name |
| `EKS_CLUSTER_NAME` | EKS cluster name, for example `mindtrack-cluster` |

The CodeBuild service role must be able to push to ECR, describe and update the EKS cluster, and authenticate to Kubernetes with the required deployment permissions.

## Configuration and Security

Before sharing or deploying this repository, replace account-specific values such as the ECR image, ACM certificate ARN, load balancer name, host name, and IAM principal ARNs with values from your own environment. Keep AWS credentials and other secrets in AWS IAM, CodeBuild environment configuration, or a secrets manager; do not commit them to this repository.

## Cleanup

To remove the Terraform-managed infrastructure:

```bash
cd eks-cluster
terraform destroy
```

Remove application resources first if they were created manually with `kubectl`.

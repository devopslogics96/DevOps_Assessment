# Terraform infrastructure

The repository is organized into reusable infrastructure modules and
independent environment roots:

```text
terraform/
  modules/
    network/  VPC, public/private subnets, NAT, ALB, target group, listener
    ecs/      ECS cluster, Fargate service/task, task security group, logs
    rds/      Private encrypted MySQL, ECS-only ingress, managed credentials
  envs/
    dev/      Development root, variables, tfvars, backend config
    prod/     Production root, variables, tfvars, backend config
```

Each environment has its own backend key, variables, `terraform.tfvars`, and
resource sizing. RDS credentials are managed by RDS and stored in Secrets
Manager. RDS is private and its MySQL ingress references only the ECS task
security group.

## Remote state setup

Create a dedicated S3 bucket before initializing Terraform. Enable bucket
versioning, block public access, and use server-side encryption. In both
`envs/dev/backend.hcl` and `envs/prod/backend.hcl`, replace the bucket
placeholder with that bucket's name. The environment keys are separate, and
S3 lock files are enabled. Initialize and apply from the environment directory:

```powershell
Set-Location terraform/envs/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use the corresponding `prod` directory for production. Do not copy state files
between environments. To validate configuration without contacting the remote
backend, run `terraform init -backend=false` and `terraform validate` in each
environment directory.

## Deployment notes

- The sample tfvars use the public NGINX image. Replace it with the application
  image when deploying the service.
- The ALB accepts HTTP by default. Set an ACM certificate ARN in the environment
  tfvars to enable HTTPS and redirect HTTP to HTTPS.
- Restrict the ALB ingress CIDR ranges for services that should not be public.
- Private ECS tasks use a NAT gateway for image pulls and outbound AWS/service
  access. NAT gateways incur charges.
- Dev uses a small single-AZ database, one-day backups, and no deletion
  protection. Prod uses a larger Multi-AZ database, 35-day backups, and
  deletion protection.
- ECS task role permissions are intentionally minimal. Add only the AWS
  permissions the application requires. For container secrets, provide
  Secrets Manager ARNs in `container_secrets`; the execution role receives
  `GetSecretValue` for those ARNs.

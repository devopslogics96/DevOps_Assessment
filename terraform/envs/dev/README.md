# Development environment

This root has its own Terraform state and resource sizing. Defaults are one
small Fargate task, a `db.t3.micro` MySQL instance, one-day RDS backup retention,
and RDS deletion protection disabled. A NAT gateway is enabled so tasks in
private subnets can pull images and reach AWS services. NAT gateways and other
AWS resources incur charges.

Before initializing, replace the bucket placeholder in `backend.hcl` with a
pre-created, private S3 bucket that has versioning enabled. Then run:

```powershell
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

The sample ALB is HTTP-only. Set `alb_certificate_arn` to an ACM certificate
ARN in the same region to enable HTTPS and redirect HTTP to HTTPS. Restrict
`allowed_alb_ipv4_cidr_blocks` for non-public development deployments.

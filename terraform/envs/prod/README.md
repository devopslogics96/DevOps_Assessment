# Production environment

This root has isolated Terraform state and production-oriented sizing: two
Fargate tasks, a `db.t3.medium` Multi-AZ MySQL instance, 35-day automated
backups, and RDS deletion protection enabled. A NAT gateway is enabled for
private subnet egress; NAT, Multi-AZ RDS, and load balancer resources incur
ongoing charges.

Before initializing, replace the bucket placeholder in `backend.hcl` with the
same pre-created, private, versioned S3 bucket used by the development
environment. The production state key is separate. Then run:

```powershell
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Configure `alb_certificate_arn` with a production ACM certificate ARN in the
selected region before exposing the service; the ALB will then redirect HTTP
to HTTPS. Restrict `allowed_alb_ipv4_cidr_blocks` if the application should not
be internet-accessible.

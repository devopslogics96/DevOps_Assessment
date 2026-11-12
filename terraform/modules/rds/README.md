# RDS module

Creates a private, encrypted MySQL RDS instance and DB subnet group. The
instance is not publicly accessible, and the RDS security group allows MySQL
port 3306 only from the supplied ECS task security group. The subnet group
checks that its subnets belong to the requested VPC and span at least two
Availability Zones.

RDS manages the master password in Secrets Manager. The module does not expose
the password as a Terraform variable or output. The caller configures instance
size, storage, backup retention, Multi-AZ, and deletion protection separately
for each environment.

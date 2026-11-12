# ECS module

Creates an ECS cluster with Container Insights, a Fargate task definition and
service, CloudWatch logs, and a task security group. The task security group
allows the configured application port only from the ALB security group.
Tasks run in private subnets without public IP addresses.

The caller supplies execution and task IAM roles, task sizing, the container
image, and the ALB target group. The execution role needs
`AmazonECSTaskExecutionRolePolicy` and permission to read any Secrets Manager
secrets used in the task definition. Application permissions belong on the
task role.

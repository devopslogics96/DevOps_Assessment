# Network module

Creates a VPC, public and private subnets across the supplied Availability
Zones, public routing through an internet gateway, optional private egress
through one NAT gateway, and an internet-facing ALB with an IP target group.
The ALB security group is exposed for use by the ECS module.

The ALB listens on HTTP port 80. If `certificate_arn` is set, the module also
creates an HTTPS listener on port 443 and redirects HTTP requests to HTTPS.
Restrict client access with `allowed_alb_ipv4_cidr_blocks`.

The NAT gateway is shared across private subnets to keep the module simple;
this is not a highly available NAT design and may incur cross-AZ data charges.
NAT gateways incur hourly and data processing costs.

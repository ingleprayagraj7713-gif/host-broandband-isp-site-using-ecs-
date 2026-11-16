# AWS CLI deployment

`deploy-test.sh` builds and pushes the current frontend and backend images, then
creates or updates the ECS services behind the existing `viztel-test-alb` in
`us-east-1`.

## Requirements

- AWS CLI credentials with permission to manage ECR, ECS, EC2 security groups,
  ELBv2, CloudWatch Logs, and task definitions.
- Docker with Buildx, `jq`, and the `ecsTaskExecutionRole` IAM role.
- An internet-facing ALB named `viztel-test-alb`, attached to at least two
  public subnets. The script reuses this ALB and its VPC.

Run from the project directory:

```bash
bash viztel-aws/aws-cli/deploy-test.sh
```

The script is safe to rerun: it reuses named ECR, security-group, target-group,
cluster, and ECS service resources, and updates the service task definitions.
It exposes HTTP on port 80; HTTPS requires a certificate and is not configured.

The script does not create or modify a database or Secrets Manager values. The
backend therefore starts in its built-in demo mode, with no persistent database
connection. Configure a real database and credentials before relying on
persistent customer data or using this environment beyond testing.

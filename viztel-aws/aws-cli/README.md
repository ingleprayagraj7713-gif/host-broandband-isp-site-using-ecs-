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

## GitHub Actions

`.github/workflows/deploy-aws.yml` validates the backend and builds the
frontend, then deploys to the existing TEST ECS services when code is pushed
to `main`. It can also be started manually from the Actions tab. ECR images are
tagged with the triggering commit SHA. The workflow uses
`deploy-test-ci.sh`, which only updates ECR images and ECS task definitions and
services; it does not create or modify network infrastructure.

Configure GitHub repository variables:

- `AWS_ROLE_ARN`: ARN of a role trusted by GitHub's OIDC provider.
- `AWS_REGION`: optional; defaults to `us-east-1`.

Create the AWS IAM OIDC provider for `https://token.actions.githubusercontent.com`
if it does not already exist. Use
[`../iam/github-actions-trust-policy.json`](../iam/github-actions-trust-policy.json)
as the role trust policy, replacing `<AWS_ACCOUNT_ID>`. Attach
[`../iam/github-actions-deploy-policy.json`](../iam/github-actions-deploy-policy.json)
after replacing `<AWS_ACCOUNT_ID>` and `<AWS_REGION>`. The policy is scoped to
the two ECR repositories, task families, ECS services, target groups, and
`ecsTaskExecutionRole` used by this TEST deployment.

The workflow expects the existing ECR repositories, `viztel-test-cluster`,
ECS services, ALB target groups, and `ecsTaskExecutionRole`. Use
`deploy-test.sh` for initial infrastructure provisioning. The OIDC trust
policy limits role assumption to this repository's `main` branch.

# Viztel Fiber TEST deployment

The current deployment script builds the Next.js frontend and Node.js API,
pushes both images to ECR, and creates or updates the ECS services and ALB
routing:

```bash
aws sts get-caller-identity
bash viztel-aws/aws-cli/deploy-test.sh
```

The script expects AWS credentials, Docker Buildx, and `jq`. It reuses the
internet-facing ALB named `viztel-test-alb` and its VPC/subnets in `us-east-1`.
It manages the HTTP listener, target groups, task definitions, log groups,
security groups, and ECS services; see
[`aws-cli/README.md`](./aws-cli/README.md) for details.

The TEST environment does not currently have an RDS database. The API runs
without a database in its demo mode; database-backed persistence is not
available. Do not put real customer data or production credentials in this
environment until a database and real Secrets Manager values are configured.

For automated TEST deployments on pushes to `main`, see
[`aws-cli/README.md`](./aws-cli/README.md#github-actions) for the GitHub Actions
OIDC setup requirements.

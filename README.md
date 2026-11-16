# Broadband ISP Site on AWS ECS

This repository contains the Viztel broadband site, Node.js API, and AWS ECS
deployment configuration.

## CI/CD

GitHub Actions validates the backend and builds the frontend, then deploys to
the TEST ECS environment on pushes to `main`. Configure the `AWS_ROLE_ARN`
repository variable with an IAM role trusted through GitHub OIDC before
deployment. See [the AWS deployment guide](./viztel-aws/aws-cli/README.md#github-actions)
for setup requirements and the manual deployment option.

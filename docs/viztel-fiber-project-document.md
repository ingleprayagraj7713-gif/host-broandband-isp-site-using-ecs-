# Viztel Fiber – Project Documentation

## 1. Project overview

This project focused on creating and deploying a broadband ISP landing experience for Viztel Fiber / YPP Fiber Broadband in the AWS TEST environment, using the `us-east-1` region. The goal was to deliver a modern, conversion-focused web presence for a fiber broadband business with local coverage messaging, plan selection, customer support, billing access, and online connection forms.

## 2. Business objective

The business needed a simple but high-impact online presence to:

- Promote fiber broadband plans in local areas
- Establish trust with local customers
- Provide a clear call-to-action for new connections
- Offer self-service and support flows
- Provide a deployment-ready AWS foundation for future scaling

## 3. Solution architecture

The deployed environment follows an AWS TEST architecture using:

- VPC with public subnets in `us-east-1a` and `us-east-1b`
- Internet-facing Application Load Balancer
- ECS Fargate frontend service
- ECS Fargate backend service
- Amazon ECR for image storage
- RDS MySQL as the database layer
- AWS Secrets Manager for environment secrets

Core flow:

- Users access the ALB public URL
- Requests to `/` are routed to the frontend service
- Requests to `/api/*` are routed to the backend service
- Backend connects to MySQL and secrets are managed centrally in Secrets Manager

## 4. Frontend implementation

The final marketing page was implemented as a responsive single-page static website using inline HTML, CSS, and JavaScript. It includes:

- Hero section with strong conversion messaging
- Plan comparison cards
- New connection form
- Customer portal flow
- Payment page mock-up
- Support and FAQ section
- Coverage and contact cards

The final page content was captured in [index.html](../index.html) and the app version in [viztel-app/frontend/index.html](../viztel-app/frontend/index.html).

## 5. Backend implementation

The backend is a lightweight Node.js and Express service providing health and supporting API routes. It was built to support testing and future integration with authentication, billing, and admin workflows.

## 6. AWS deployment and validation

The project was deployed in AWS `us-east-1` and validated with live checks.

### Verified status

- Frontend ALB endpoint returned HTTP 200
- Backend health endpoint returned valid JSON
- Main public endpoint: http://viztel-test-alb-394211086.us-east-1.elb.amazonaws.com/
- Backend health: http://viztel-test-alb-394211086.us-east-1.elb.amazonaws.com/api/health

### Live response sample

```json
{"status":"ok","database":"connected","result":{"ok":1}}
```

## 7. Key files in the project

- [index.html](../index.html) — final landing page HTML
- [viztel-app/frontend/index.html](../viztel-app/frontend/index.html) — static page variant in app workspace
- [viztel-aws/docker/Dockerfile.frontend](../viztel-aws/docker/Dockerfile.frontend) — production frontend container definition
- [viztel-aws/README.md](../viztel-aws/README.md) — AWS deployment guide

## 8. Results

The project demonstrated a complete low-cost, production-style broadband site deployment using AWS-native infrastructure with:

- clean responsive UI
- local promotional marketing positioning
- billing and account flows in the mock demo experience
- live AWS validation
- reusable architecture for future expansion

## 9. Screenshot

A live homepage screenshot was captured from the deployed site and used for social sharing.

Use the live page for reference:

- http://viztel-test-alb-394211086.us-east-1.elb.amazonaws.com/

## 10. Recommended next steps

- Add a real domain and HTTPS certificate
- Integrate live Razorpay / payment API
- Add authentication for portal users
- Secure the admin dashboard
- Expand analytics and campaign tracking
- Move from TEST to production-ready infrastructure

---

This project shows how a broadband ISP can launch quickly with a strong frontend, cloud-ready deployment, and a validation path that is easy to present to clients or stakeholders.

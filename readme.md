## Deployment for Echo service;

### Prerequisites:

1. AWS CLI installed
2. Docker installed
3. Terraform
4. Python

## Deployment Steps

1. Configure your terraform variables to match your aws account in /terraform folder
2. Build and push Docker images to ECR - 3 ECR repositories follow AWS steps to create and push to containers
3. Deploy Infrastructure with Terraform
	- in terraform dir init terraform
	- terraform plan and apply to initialize
### Testing the service~
1. DNS service will be output by terraform
2. Using netcat nc <my-service> interact with you preferred echo command

## Cleanup with terraform destroy
# Terraform Infrastructure for 3-Tier Application
This Terraform project sets up a 3-tier application architecture on AWS, consisting of a frontend (React), backend (Node.js), and MongoDB database.

## Overview
This Terraform configuration deploys the following AWS resources:

* **Frontend:** EC2 instances running a React application with load balancing.
* **Backend:** EC2 instances running a Node.js application with load balancing.
* **Database:** EC2 instances hosting a MongoDB database.
* **Networking:** VPC, Subnets, Security Groups, and Route Tables configured to support the application tiers.


## Prerequisites
Before you begin, ensure you have the following:

* **Terraform CLI installed locally.**
* **AWS CLI configured with appropriate credentials and permissions.**
* **SSH key pair for accessing EC2 instances.**

## Getting Started
### Installation
1. Clone this repository:

`bash`
```
git clone <repository-url>
cd 3-tier-Application-via-Terraform
```
2. Initialize Terraform:

`csharp`
```
terraform init
```

### Configuration
1. Customize the deployment by modifying variables.tf to match your requirements.

2. Update backend.tf with your preferred backend configuration for state management.

## Deploying Infrastructure
To deploy the infrastructure:

1. Review the planned changes:

```
terraform plan
```

2. Apply the changes:

```
terraform apply
```

3. Confirm by typing **yes** when prompted.

## Structure

* **main.tf:** Defines the main infrastructure components.
* **variables.tf:** Contains input variables for customization.
* **networking.tf:** Configures VPC, subnets, and networking components.
* **frontend.tf:** Configures the frontend application tier with EC2 instances and load balancing.
* **backend.tf:** Configures the backend application tier with EC2 instances and load balancing.
* **database.tf:** Configures the MongoDB database tier with EC2 instances.
* **outputs.tf:** Defines the output values to display after deployment.

## Resources

* **EC2 Instances:** Deployed for frontend, backend, and database tiers.
* **Load Balancers:** Ensures high availability and distributes traffic across instances.
* **Security Groups:** Controls inbound and outbound traffic to instances.
* **VPC:** Virtual Private Cloud for network isolation.
* **Subnets:** Segments network traffic and ensures availability zones coverage.
* **Route Tables:** Directs traffic between subnets and internet gateways.

## Variables
* **vpc_name:** Name for the VPC and related resources.
* **region:** AWS region to deploy resources.
* **public_key_path:** Path to the public key file for SSH access.
* **frontend_instance_type:** Instance type for the frontend EC2 instances and same for backend and database.

## Contributing
Contributions are welcome! Fork this repository, make your changes, and submit a pull request.

# AWS Three-Tier Architecture with Terraform

## Project Overview

This project demonstrates a production-style AWS Three-Tier Architecture deployed using Terraform Infrastructure as Code (IaC).

The architecture is designed following cloud security, scalability, and high availability best practices commonly used in enterprise environments.

The infrastructure is fully modularized using Terraform modules and separated into multiple environments (`dev`, `prod`) for better maintainability and scalability.

---

# Architecture

The system is divided into three logical layers:

## 1. Presentation Tier (Web Layer)

* Application Load Balancer (ALB)
* Public Subnets
* Internet Gateway
* NAT Gateway

This layer handles incoming traffic from the Internet and distributes requests to the application servers.

---

## 2. Application Tier

* EC2 Instances
* Auto Scaling Group
* Private Application Subnets

This layer processes business logic and communicates with the database layer securely through private networking.

---

## 3. Database Tier

* Amazon RDS (MySQL/PostgreSQL)
* Private Database Subnets

The database layer is completely isolated from the Internet and only accessible from the application layer.

---

# Architecture Flow

```text
Internet
    ↓
Application Load Balancer
    ↓
Application EC2 Instances (Private Subnet)
    ↓
Amazon RDS Database (Private Subnet)
```

---

# Technologies Used

## Cloud Provider

* AWS (Amazon Web Services)

## Infrastructure as Code

* Terraform

## AWS Services

* VPC
* Subnets
* Route Tables
* Internet Gateway
* NAT Gateway
* Security Groups
* Application Load Balancer
* EC2
* Auto Scaling Group
* Amazon RDS
* CloudWatch

---

# Key Features

* Modular Terraform architecture
* Multi-AZ deployment
* Public and private subnet segmentation
* High availability networking
* NAT Gateway per Availability Zone
* Secure database isolation
* Scalable application layer
* Infrastructure as Code best practices
* Environment separation (`dev`, `prod`)

---

# Project Structure

```text
AWS-Three-Tier-Architecture/
│
├── backend/
│
├── environments/
│   ├── dev/
│   └── prod/
│
├── modules/
│   ├── alb/
│   ├── autoscaling/
│   ├── ec2/
│   ├── monitoring/
│   ├── rds/
│   ├── security-group/
│   └── vpc/
│
├── providers.tf
├── versions.tf
├── outputs.tf
└── README.md
```

---

# Networking Design

## Public Subnets

Used for:

* Application Load Balancer
* NAT Gateway
* Bastion Host (optional)

## Private Application Subnets

Used for:

* EC2 Application Servers
* Auto Scaling Group

Private application instances access the Internet through NAT Gateway only.

## Private Database Subnets

Used for:

* Amazon RDS

Database subnets do not have direct Internet access for improved security.

---

# Security Design

* Private EC2 instances without public IP
* Database isolation in private subnets
* Security Group segmentation
* Controlled inbound/outbound traffic
* NAT Gateway for secure outbound Internet access
* Least privilege network architecture

---

# Deployment Workflow

## Initialize Terraform

```bash
terraform init
```

## Validate Terraform Configuration

```bash
terraform validate
```

## Preview Infrastructure Changes

```bash
terraform plan
```

## Deploy Infrastructure

```bash
terraform apply
```

---

# Future Improvements

* Bastion Host
* AWS Systems Manager Session Manager
* HTTPS with ACM
* Route53
* AWS WAF
* CloudFront
* CI/CD Pipeline
* Docker & Kubernetes
* Amazon EKS
* Blue/Green Deployment
* Monitoring Dashboard
* Centralized Logging

---

# Learning Objectives

This project helps practice:

* AWS Networking
* Terraform Modules
* Infrastructure as Code
* Cloud Security
* High Availability Architecture
* Scalable Cloud Infrastructure
* Production-style AWS Design

---

# Author

Nguyen Dinh Tri


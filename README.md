# Deploying a Web Server in Azure using Packer and Terraform
  
## An overview of the project  
The objective of this project is to deploy a web server in Azure using Terraform template for creating infrastructure as code.   

## Instructions for running the Packer and Terraform templates  
A short description of how to customize it for use (i.e., how to change the vars.tf file) 
  
### Packer  
Packer is used to create the server image in Azure which is later used by Terraform for deploying the web server.
  
### Terraform  
Below are the steps for running Terraform:  
Run terraform init  
Run terraform plan -out solution.plan  
Run terraform apply  




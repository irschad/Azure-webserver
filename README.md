# Deploy a Web Server in Azure using Packer and Terraform
  
## An overview of the project  
The objective of this project is to deploy a web server and related resources in Azure using Packer for image build and Terraform for infrastructure as code.   

## Instructions for running the Packer and Terraform templates  
A short description of how to customize it for use (i.e., how to change the vars.tf file) 
  
### Packer  
Packer is used to create the server image in Azure which is later used by Terraform for deploying the web server.
Below are the steps followed for Packer:  
* Install packer (https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)  
* Create & configure Azure credentials for Packer (https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer)
* Build packer image by running **packer build server.json** 

  
### Terraform  
Below are the steps followed for Terraform:  
* Create main.tf for instructions for creating all resources and vars.tf for variables. 
* Run **terraform init**  
* Run **terraform plan -out solution.plan**
* Review the output
* Run **terraform apply**
* Check all resources created 
* Test the load balancer URL
* Run **terraform destroy** to delete all resources created with terraform apply.    




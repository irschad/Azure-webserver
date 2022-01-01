# Deploy a Web Server in Azure using Packer and Terraform
  
## An overview of the project  
The objective of this project is to deploy a web server and related resources in Azure using Packer for image build and Terraform for infrastructure as code.   

## Instructions for running the Packer and Terraform templates  
  
### Packer  
Packer is used to create the server image in Azure which is later used by Terraform for deploying the web server.
Below are the steps followed for Packer:  
* Install packer (https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)  
* Create & configure Azure credentials for Packer (https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer)
* Build packer image by running **packer build server.json** 

  
### Terraform  
Terraform is used for defining and managing infrastructure as code. Below are the steps followed for Terraform:  
* Create main.tf for instructions for creating all resources and vars.tf for variables (including reference to source image as packer image created previously).  
  (Ensure customizable variables such as number of VMs, location, packer image source, size of VMs, etc. are configured in vars.tf file). 
* Run **terraform init**  
* Run **terraform plan -out solution.plan**
* Review the output
* Run **terraform apply**
* Check all resources are created and working as expected.
* Run **terraform destroy** to delete all resources created with terraform apply.    




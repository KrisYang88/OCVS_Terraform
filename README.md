# Stack to create an OCVS environment.

## Architecture 
This runbook provides the terraform and steps to deploy Oracle Cloud VMware Service using Resource Manager. A single deployment of the stack creates a public bastion, a private jumphost and a single VMware Software Defined Data Center (SDDC) within Oracle Cloud. The stack can also be used to launch an SDDC within an existing VCN, and connections between multiple SDDC vCenters within that VCN can be configured using vCenter Enhanced Linked Mode (ELM).

## Policies to deploy the stack: 
```
allow service compute_management to use tag-namespace in tenancy
allow service compute_management to manage compute-management-family in tenancy
allow group user to manage all-resources in compartment compartmentName
```

## Supported Shapes & OS Distributions: 
The stack currently supports the below shapes for the bastion, jumphost and sddc.

|     Bastion   |   JumpHost   |              SDDC                |
|---------------|--------------|----------------------------------|
|   All Shapes  |  All Shapes  |  BM.DenseIO.E4 (32,64,128 cores) | 
|               |              |  BM.DenseIO2.52                  |


The stack currently supports the below OS distributions for the bastion and jumphost. 

|     Bastion   |   JumpHost            |
|---------------|-----------------------|
|   OEL6,7,8,9  |  Windows 12,16,19,22  |  


## Stack Deployment
You can start by logging in the Oracle Cloud console. If this is the first time, instructions are available [here](https://docs.cloud.oracle.com/iaas/Content/GSG/Tasks/signingin.htm).
Select the region in which you wish to create your instance via the top right dropdown list of the console. 

### Resource Manager
In the OCI console, there is a Resource Manager available that will create all the resources needed. The region in which you create the stack will be the region in which it is deployed.

  1. Select the hamburger menu at the top left, then select Developer Services --> Resource Manager --> Stacks. Choose the compartment name on the left filter menu where the stack will be run.

  2. Click 'Create Stack' and change the Terraform Configuration Source to a .zip file.

  3. Download this repository as a zip and upload it into the stack. 

Move to the [Select Variables](#select-variables) section to complete configuration of the stack.

### Select Variables

Select 'Next' and fill in the variables, as follows:

**Infrastructure Configuration**
* Target Compartment: Specify the compartment where you want to launch the infrastructure
* Public SSH Key: Upload or paste in your ssh public key
* Use Custom Infrastructure Name: Leave unchecked if you want to use the default naming convention. A random pet name and adjective is used for the bastion, jumphost and general VCN networking. Random string of 6 characters is used to prefix the SDDC name since VMware has special requirements for naming. If you specify a custom name for the infrastructure, be sure to specify 10 characters or less and no special characters other than a hyphen.

**General Network Options**

* Use Existing VCN: Leave unchecked if you want the stack to create a new VCN with required networking components. If you specify an existing VCN, ensure it has all required network components created, including route tables, security lists, one public and private subnet, internet and nat gateway, etc.
* VCN, Public, Private IP Ranges: Leave as default or customize to your requirements


**Public Bastion & Private Jumphost Options:**

* Availability Domain: Specify the availability domain location for the bastion and jumphost
* Shapes: Specify the instance shape desired for the bastion and jumphost.
* Image ID: Specify the Oracle Linux Image ID desired for the bastion and Windows Image ID desired for the jumphost. Note that it is important to choose the correct OS distribution for the instance shape you are using - for example 'Gen2-GPU' for GPU shapes only, 'aarch64' for arm instances only, x86 for AMD / Intel shapes and VM for VM shapes only.
* OCPU's: Specify the OCPU's desired for both the bastion and jumphost. Note that OCPU refers to true cores and not threads.
* Use Custom Memory Size: This option will only appear for flex shapes. When selected, you can change the default memory up or down based on workload and cost requirements. The minimum memory required is 1 GB per core.
* Size of the Boot Volume: Specify the boot volume size for the bastion and jumphost or leave as default.


**SDDC Compute & Software Options:**

* Availability Domain: Specify the availability domain for the SDDC
* Shape of ESXi Hosts: Currently only BM.DenseIO.E4.128 and BM.DenseIO2.52 shapes are supported. 
* Cores: If BM.DenseIO.E4.128 is selected, you may specify 32, 64 or 128 cores, depending on your workload requirements. Only 52 cores is available if BM.DenseIO.52 is used.
* Use a single ESXi host on OCVS: Select if you only want a single ESXi host provisioned. If this is unchecked, a minimum of 3 ESXi hosts will be provisioned.
* Initial Cluster Size: The minimum cluster size is 3 ESXi hosts. Currently, scaling up to 64 hosts is supported.
* Enable HCX: By default, this is checked to install the HCX plugin. Note that you cannot install this plugin after the SDDC is created.
* VMware Software Version: Select the desired VMware version. The latest version available is the default.
* Pricing Interval: Hourly pricing is the default, with a minimum of 8 hours of commited host runtime.

**SDDC Networking Options:**
* SDDC Workload Subnet CIDR Range: Specify a CIDR range for the sddc workload subnet
* Use a Default Provisioning CIDR Range for the SDDC: Leave as checked to keep the default settings for the SDDC provisioning subnet and VLAN CIDR ranges. Specify new CIDR ranges if an existing VCN is being pointed to and the default CIDR ranges are already used by other SDDC's/resources.  

**Additional FSS (NFS) Datastore:**
* Create FSS: Leave checked if you want to create an NFS v3-based datastore and mount it to the vCenter.


### Run the Stack

Now that your stack is created, you can run jobs. Select the stack that you created. In the 'Terraform Actions' dropdown menu, run 'Apply' to launch the infrastructure.

### Access your Environment

Once your job has completed successfully in Resource Manager, you can find all login commands from the lower left menu under **Outputs**. This includes the ssh login command to the bastion, the tunnel details to the jumphost (note, use Putty and RDP to connect to a Windows jumphost), and the vCenter login details.

### Post Configuration
If FSS is configured, you can refer to the following [Oracle FSS VMware blog](https://blogs.oracle.com/cloud-infrastructure/post/oci-fss-service-is-now-vmware-certified) to mount it to the vCenter as a datastore. To configure ELM between vCenters, refer to the following [Oracle OCVS with ELM blog](https://docs.oracle.com/en/learn/vcenter_elm_ocvs/index.html) for instructions.

# GCP Service monitor

This repository is a fork from [terraform-google-api-police](https://github.com/terraform-google-modules/terraform-google-api-police). The deployment will create a custom Cloud Function that monitors and disables unapproved Google APIs within a GCP Organization. Upon detection that an unapproved API has been enabled, the Cloud Function will actively and automatically disable the API in violation of this policy. This is accomplished by exporting Cloud Audit logs looking for the enablement of APIs under an organization. Those logs are then exported via a Cloud Logging Organizational Aggregated Export sink to a Pub/Sub topic, which will then trigger the Cloud Function. 

## Requirements

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 0.12.x
- [terraform-provider-google](https://github.com/terraform-providers/terraform-provider-google) plugin v3.51.0
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) plugin v3.51.0

### Enabled APIs
The following APIs must be enabled in the project:
- Logging: `logging.googleapis.com`
- Monitoring: `monitoring.googleapis.com`

### Service account permissions
The **Terraform service account** used to run this module must have the following permissions:

#### Cloud Function permissions
* cloudfunctions.functions.create
* cloudfunctions.functions.delete
* cloudfunctions.functions.sourceCodeSet
* cloudfunctions.functions.update

#### Service Account management permissions
* iam.serviceAccounts.create
* iam.serviceAccounts.delete

#### Pub/Sub permissions
* pubsub.topics.create
* pubsub.topics.delete
* pubsub.topics.setIamPolicy

#### Project IAM permission
* resourcemanager.projects.setIamPolicy

#### Organization IAM Permission
* resourcemanager.organizations.setIamPolicy

#### Organization Log Sink
* logging.sinks.create
* logging.sinks.delete

#### Service Management permissions
* servicemanagement.services.bind
* serviceusage.services.enable

#### Storage permissions
* storage.buckets.create
* storage.buckets.delete
* storage.buckets.getIamPolicy


## Deployment
-  Create a Google Storage bucket to store Terraform state 
-  `gsutil mb gs://<your state bucket>`
-  Copy terraform.tfvars.template to terraform.tfvars 
-  `cp terraform.tfvars.template  terraform.tfvars`
-  Update required variables  
- `terraform init` to get the plugins
-  Enter Google Storage bucket that will store the Terraform state
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

## Validate

If you deployed the Cloud Function without modifying the list `translate.googleapis.com` should be blocked. 
```shell
$ gcloud config set project <project_id that you used in step 4>
$ gcloud services list #list currently enabled APIs in project
$ gcloud services enable translate.googleapis.com #try to enable blocked translate API
$ gcloud services enable vision.googleapis.com #enable not blocked API
$ gcloud services list #verify that vision.googleapis is enabled, but translate.googleapis is not
```



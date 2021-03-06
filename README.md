# Cross-cloud - multi-cloud provisioner

The multi-cloud kubernetes provisioner component of the [Cross-Cloud CI](https://github.com/crosscloudci/crosscloudci) project.

### What is Cross-cloud?


A Kubernetes provisioner supporting multiple clouds (eg. AWS, Azure, Google, Equinix Metal) which

  * Creates K8s clusters on cloud providers
  * Supplies conformance validated Kubernetes end-points for each cloud provider with cloud specific features enabled

### How to Use Cross-cloud 

You have to have a working [Docker environment](https://www.docker.com/get-docker)

Note: 147.75.69.23 is the IP address of the DNS server for Cross Cloud deployed Nodes. Should you wish to be able to reach your Nodes by name from outside the cluster, that IP needs to be in your /etc/resolv.conf but it is not a delegating resolver, so it shouldn't be the only nameserver in your resolv.conf.

##### Quick start for AWS

**Pre-reqs:**
_[IAM User](https://console.aws.amazon.com/iam) with the following Permissions:_
- AmazonEC2FullAccess
- AmazonS3FullAccess
- AmazonRoute53DomainsFullAccess
- AmazonRoute53FullAccess
- IAMFullAccess
- IAMUserChangePassword

_AWS credentials_
```
export AWS_ACCESS_KEY_ID="YOUR_AWS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
export AWS_DEFAULT_REGION=”YOUR_AWS_DEFAULT_REGION” # eg. ap-southeast-2
```

**Run the following to provision a Kubernetes cluster on AWS:**
```bash
docker run \
  -v /tmp/data:/cncf/data \
  -e NAME=cross-cloud \
  -e CLOUD=aws    \
  -e COMMAND=deploy \
  -e BACKEND=file  \ 
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID    \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY    \
  -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION    \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

##### Quick start for GCE
 
**Pre-reqs:**
[Project created on Google Cloud](https://console.developers.google.com/projectcreate) (eg. test-cncf-cross-cloud)

_Google Cloud JSON configuration file for authentication._  (This file is downloaded directly from the [Google Developers Console](https://console.developers.google.com/))

1. Log into the Google Developers Console and select a project.
1. The API Manager view should be selected, click on "Credentials" on the left, then "Create credentials," and finally "Service account key."
1. Select "Compute Engine default service account" in the "Service account" dropdown, and select "JSON" as the key type.
1. Clicking "Create" will download your credentials.
1. Rename this file to credentials-gce.json and move to your home directory (~/credentials-gce.json)

_Google Project ID_

1. Log into the [Google Developers Console](https://console.developers.google.com/) to be sent to the [Google API library page](https://console.developers.google.com/apis/library) screen
1. Click the `Select a project` drop-down in the upper left
1. Copy the Project ID for the desired project from the window that shows
Eg. test-cncf-cross-cloud

**Run the following to provision a Kubernetes cluster on GCE:**
``` bash
export GOOGLE_CREDENTIALS=$(cat ~/credentials-gce.json)
docker run \
  -v /tmp/data:/cncf/data  \
  -e NAME=cross-cloud  \
  -e CLOUD=gce    \
  -e COMMAND=deploy  \
  -e BACKEND=file  \ 
  -e GOOGLE_REGION=us-central1    \
  -e GOOGLE_ZONE=us-central1-a  \
  -e GOOGLE_PROJECT=test-cncf-cross-cloud  \
  -e GOOGLE_CREDENTIALS="${GOOGLE_CREDENTIALS}" \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

##### Quick start for OpenStack

You will need a full set of credentials for an OpenStack cloud, including
authentication endpoint.

**Run the following to provision an OpenStack cluster:**
``` bash
docker run \
  -v $(pwd)/data:/cncf/data \
  -e NAME=cross-cloud \
  -e CLOUD=openstack \
  -e COMMAND=deploy \
  -e BACKEND=file \
  -e TF_VAR_os_auth_url=$OS_AUTH_URL \
  -e TF_VAR_os_region_name=$OS_REGION_NAME \
  -e TF_VAR_os_user_domain_name=$OS_USER_DOMAIN_NAME \
  -e TF_VAR_os_username=$OS_USERNAME \
  -e TF_VAR_os_project_name=$OS_PROJECT_NAME \
  -e TF_VAR_os_password=$OS_PASSWORD \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

##### Quick start for vSphere via VMware Cloud (VMC) on AWS

The vSphere provider requires vSphere host and credential information,
as well as credentials for the linked AWS account:

**Run the following to provision a vSphere cluster:**
``` bash
docker run \
  --rm \
  --dns 147.75.69.23 --dns 8.8.8.8 \
  -v $(pwd)/data:/cncf/data \
  -e NAME=cross-cloud \
  -e CLOUD=vsphere \
  -e COMMAND=deploy \
  -e BACKEND=file \
  -e VSPHERE_SERVER=$VSPHERE_SERVER \
  -e VSPHERE_USER=$VSPHERE_USER \
  -e VSPHERE_PASSWORD=$VSPHERE_PASSWORD \
  -e VSPHERE_AWS_ACCESS_KEY_ID=$VSPHERE_AWS_ACCESS_KEY_ID \
  -e VSPHERE_AWS_SECRET_ACCESS_KEY=$VSPHERE_AWS_SECRET_ACCESS_KEY \
  -e VSPHERE_AWS_REGION=$VSPHERE_AWS_REGION \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:ci-stable-v0-2-0
```

#### Quickstart for metal.equinix.com

Packet.net requires an auth token and a project id.

To deploy to equinix metal:
```bash
docker run \
  -v /tmp/data:/cncf/data \
  --dns 147.75.69.23 --dns 8.8.8.8 \
  -e NAME=cross-cloud \
  -e CLOUD=packet    \
  -e COMMAND=deploy \
  -e BACKEND=file  \
  -e PACKET_AUTH_TOKEN=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

To destroy your cluster in packet:
```bash
docker run \
  -v /tmp/data:/cncf/data \
  --dns 147.75.69.23 --dns 8.8.8.8 \
  -e NAME=cross-cloud \
  -e CLOUD=packet    \
  -e COMMAND=destroy \
  -e BACKEND=file  \
  -e PACKET_AUTH_TOKEN=${PACKET_AUTH_TOKEN} \
  -e TF_VAR_packet_project_id=${PACKET_PROJECT_ID} \
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

Note: 147.75.69.23 is the IP address of the DNS server for Cross Cloud
deployed Nodes.  Should you wish to be able to reach your Nodes by name from
outside the cluster, that IP needs to be in your /etc/resolv.conf *but* it is
not a delegating resolver, so it shouldn't be the *only* nameserver in your
resolv.conf

#### General usage and configuration

Minimum required configuration to use Cross-cloud to deploy a Kubernetes cluster on Cloud X.
```bash
docker run \
  -v /tmp/data:/cncf/data \
  -e NAME=cross-cloud
  -e CLOUD=<aws|gke|gce|openstack|packet>    \
  -e COMMAND=<deploy|destory> \
  -e BACKEND=<file|s3>  \ 
  <CLOUD_SPECIFIC_OPTIONS>
  <KUBERNETES_CLUSTER_OPTIONS>
  -ti registry.cncf.ci/cncf/cross-cloud/provisioning:production
```

#### Common Options
* -e CLOUD=<aws|gke|gce|openstack|packet> # Choose the cloud provider.  Then add the appropriate cloud specific options below.
* -e COMMAND=<deploy|destory>
* -e BACKEND=<file|s3>   # File will store the Terraform State file to Disk / S3 will store the Terraform Statefile to a AWS s3 Bucket
  

#### Cloud Specific Options
AWS:
 * -e AWS_ACCESS_KEY_ID=secret
 * -e AWS_SECRET_ACCESS_KEY=secret
 * -e AWS_DEFAULT_REGION=ap-southeast-2

Equinix Metal:
 * -e PACKET_AUTH_TOKEN=secret
 * -e TF_VAR_packet_project_id=secret 

GCE/GKE:
 * -e GOOGLE_CREDENTIALS=secret
 * -e GOOGLE_REGION=us-central1
 * -e GOOGLE_PROJECT=test-163823
 * -e GOOGLE_ZONE=us-central1-a

OpenStack:
 * -e TF_VAR_os_auth_url=$OS_AUTH_URL
 * -e TF_VAR_os_region_name=$OS_REGION_NAME
 * -e TF_VAR_os_user_domain_name=$OS_USER_DOMAIN_NAME
 * -e TF_VAR_os_username=$OS_USERNAME
 * -e TF_VAR_os_project_name=$OS_PROJECT_NAME
 * -e TF_VAR_os_password=$OS_PASSWORD

vSphere via VMware Cloud (VMC) on AWS:
 * -e VSPHERE_SERVER=1.2.3.4
 * -e VSPHERE_USER=admin
 * -e VSPHERE_PASSWORD=notblank
 * -e VSPHERE_AWS_ACCESS_KEY_ID=public
 * -e VSPHERE_AWS_SECRET_ACCESS_KEY=secret
 * -e VSPHERE_AWS_REGION=us-west-2

#### Kubernetes Cluster Options
Custom Configuration options for the Kubernetes Cluster:
* -e TF_VAR_pod_cidr=10.2.0.0/16      # Set the Kubernetes Cluster POD CIDR
* -e TF_VAR_service_cidr=10.0.0.0/24  # Set the Kubernetes Cluster SERVICE CIDR
* -e TF_VAR_worker_node_count=3       # Set the Number of Worker nodes to be Deployed in the Cluster
* -e TF_VAR_master_node_count=3       # Set the Number of Master nodes to be Deployed in the Cluster
* -e TF_VAR_dns_service_ip=10.0.0.10  # Set the Kubernetes DNS Service IP
* -e TF_VAR_k8s_service_ip=10.0.0.1   # Set the Kubernetes Service IP


### Additional Documentation

 * [FAQ](FAQ.md) - Frequently Asked Questions

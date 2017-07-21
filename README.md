# cross-cloud
Cross Cloud Continuous Integration

#### What is cross-cloud?

This cross-cloud project aims to demonstrate cross-project compatibility in the
CNCF by building, E2E testing and deploying selected CNCF projects to multiple
clouds using continuous integration (CI). The initial proof of concept is being
done by deploying a Kubernetes cluster with CoreDNS and Prometheus to AWS and
Packet. The eventual goal is to support all CNCF projects on AWS, Packet, GCE,
GKE, Bluemix and Azure.

Our cross-cloud provisioning is accomplished with the terraform modules for
[AWS](./aws), [Azure](./azure), [GCE](./gce), [GKE](./gke), [Packet](./packet)
which deploy kubernetes using a common set of variables producing KUBECONFIGs
for each.

Each project is deployed and tested on each of the clouds. For now the results
will be available as we run each cross-cloud CI job, but plan to run them daily
and eventually per commit.

Our first public demo of cross-cloud pipeline was recorded during [June 27th CNCF CI WG Meeting](https://www.youtube.com/watch?v=Jc5EJVK7ZZk&feature=youtu.be&t=310)

[![eventually targeting all clouds](docs/images/eventually-targeting-all-clouds.png)](https://www.youtube.com/watch?v=Jc5EJVK7ZZk&featu\
re=youtu.be&t=310)

#### How does it work?

We fork CNCF projects into the CNCF.ci gitlab server (https://gitlab.cncf.ci/)
where we add a .gitlab-ci.yml config file to drive the CI process.

Each push to projects branches we are interested in will generate binaries,
tests, and container images exported as ci variables that will allow continous
deployment of that projects artifacts.

We frequent #cncf-ci on [slack.cncf.io](slack.cncf.io) and CNCF [wg-ci](https://github.com/cncf/wg-ci) [mailinglist](https://lists.cncf.io/mailman/listinfo/cncf-ci-public). 

### CNCF Project Pipelines

![cross-cloud-pipeline](docs/images/cncf-project-pipelines.png)

The CI yaml for each project builds artifacts needed to deploy and e2e test and
makes them available as environment variables.

```
ALERT_MANAGER_IMAGE=registry.cncf.ci/prometheus/alertmanager
ALERT_MANAGER_TAG=ci-v0.6.2.e9aefe84.5699
COREDNS_IMAGE=registry.cncf.ci/coredns/coredns
COREDNS_TAG=ci-v007.97c730ab.5713
KUBERNETES_IMAGE=registry.cncf.ci/kubernetes/kubernetes/hyperkube-amd64
KUBERNETES_TAG=ci-v1-6-3.job.5949
NODE_EXPORTER_IMAGE=registry.cncf.ci/prometheus/node_exporter
NODE_EXPORTER_TAG=ci-v0.14.0.ae1e00a5.5696
PROMETHEUS_IMAGE=registry.cncf.ci/prometheus/prometheus
PROMETHEUS_TAG=ci-v1.6.3.fd07e315.6097
```

# Cross-Cloud CI Pipeline Stages

### CNCF Artifacts 

In our first stage we tie together a particular set of project branches
(stable,master,alpha) and collect the release.env

We override these variables for the sets of branches we want to test together:

```yaml
variables:
  K8S_BRANCH: ci-master
  COREDNS_BRANCH: ci-master
  PROMETHEUS_BRANCH: ci-master
  NODE_EXPORTER_BRANCH: ci-master
  ALERT_MANAGER_BRANCH: ci-master
```
![cncf-artifacts-stage](docs/images/cncf-artifacts-stage.png)

### Cross Cloud

The Cross cloud repo itself includes a [container](Dockerfile) which is used to
deploy k8s on several clouds, the resulting KUBECONFIG is made available for
cross-project deployments. The cross-cloud provisioning container is intended to
include multiple approaches to provisining containers.

We pin the versions of the provisioning dependencies at the top of our
[container](Dockerfile):

```
FROM golang:alpine
MAINTAINER "Denver Williams <denver@ii.coop>"
ENV KUBECTL_VERSION=v1.5.2
ENV HELM_VERSION=v2.4.1
ENV GCLOUD_VERSION=150.0.0
ENV AWSCLI_VERSION=1.11.75
ENV AZURECLI_VERSION=2.0.2
ENV PACKETCLI_VERSION=1.33
ENV TERRAFORM_VERSION=0.9.5
```

The cross-cloud
[provision.sh entrypoint](https://gitlab.cncf.ci/cncf/cross-cloud/blob/master/provision.sh)
selects the provisioning approach and name for the cluster (currently based on
the branch). Multiple approaches can be added here. This is where we want to
standardize what variables should drive cluster deployments across the clouds.

```
$ /cncf/provision.sh aws-deploy aws-ci-stable
Kubernetes master is running at
https://kz8s-apiserver-aws-mvci-stable-8857.ap-southeast-2.elb.amazonaws.com

$ /cncf/provision.sh aws-deploy packet-ci-stable
Kubernetes master is running at
https://endpoint.packet-mvci-stable.cncf.ci
```

The terraform module for each cloud has similar inputs for cross-cloud
deployments in addition to cloud specific variables:

 * Inputs: [AWS](https://gitlab.cncf.ci/cncf/cross-cloud/blob/master/aws/input.tf), [Azure](https://gitlab.cncf.ci/cncf/cross-cloud/blob/master/azure/input.tf), [Packet](https://gitlab.cncf.ci/cncf/cross-cloud/blob/master/packet/input.tf) 

```
# Kubernetes
variable "cluster_domain" { default = "cluster.local" }
variable "pod_cidr" { default = "10.2.0.0/16" }
variable "service_cidr"   { default = "10.0.0.0/24" }
variable "k8s_service_ip" { default = "10.0.0.1" }
variable "dns_service_ip" { default = "10.0.0.10" }
variable "master_node_count" { default = "3" }
variable "worker_node_count" { default = "3" }
variable "worker_node_min" { default = "3" }
variable "worker_node_max" { default = "5" }
```

```
# AWS Specific Settings
variable "aws_region" { default = "ap-southeast-2" }
variable "aws_key_name" { default = "aws" }
variable "aws_azs" { default = "ap-southeast-2a,ap-southeast-2b,ap-southeast-2c" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "allow_ssh_cidr" { default = "0.0.0.0/0" }
```

```
# Packet Specific Settings
variable "packet_facility" { default = "sjc1" }
variable "packet_billing_cycle" { default = "hourly" }
variable "packet_operating_system" { default = "coreos_stable" }
variable "packet_master_device_plan" { default = "baremetal_0" }
variable "packet_worker_device_plan" { default = "baremetal_0" }
```

![cross-cloud-stage](docs/images/cross-cloud-stage.png)

### Cross Project

We are currently using helm and overriding the image_url and image_tag with our
CI generated artifact.

![cross-cloud-stage](docs/images/cross-project-stage.png)

### CNCF e2e

Initially we are e2e testing head and the last stable release of Kubernetes, CoreDNS
and Prometheus.

```
helm install --name coredns --set image.repository=${COREDNS_IMAGE} --set image.tag=${COREDNS_TAG} … stable/coredns

helm install --name prometheus --set server.image.repository=$PROMETHEUS_IMAGE --set server.image.tag=$PROMETHEUS_TAG --set nodeExporter.image.repository=$NODE_EXPORTER_IMAGE --set … stable/prometheus
```

![cncf-e2e-stage](docs/images/cncf-e2e-stage.png)

Feedback on our approach to building and e2e testing welcome:

 * https://github.com/ii/kubernetes/pull/1 => https://gitlab.cncf.ci/kubernetes/kubernetes/blob/ci-master/.gitlab-ci.yml
 * https://github.com/ii/coredns/pull/1 => https://gitlab.cncf.ci/coredns/coredns/blob/ci-master/.gitlab-ci.yml
 * https://github.com/ii/prometheus/pull/1 https://gitlab.cncf.ci/prometheus/prometheus/blob/ci-master/.gitlab-ci.yml
 * https://github.com/ii/alertmanager/pull/1 => https://gitlab.cncf.ci/prometheus/alertmanager/blob/ci-master/.gitlab-ci.yml
 * https://github.com/ii/node_exporter/pull/1 => https://gitlab.cncf.ci/prometheus/node_exporter/blob/ci-master/.gitlab-ci.yml

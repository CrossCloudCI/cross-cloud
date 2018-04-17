resource "gzip_me" "ca" {
  input = "${ var.ca }"
}

resource "gzip_me" "ca_key" {
  input = "${ var.ca_key }"
}

resource "gzip_me" "master" {
  count = "${ var.master_node_count }"
  input = "${ element(split(",", var.master), count.index) }"
}

resource "gzip_me" "master_key" {
  count = "${ var.master_node_count }"
  input = "${ element(split(",", var.master_key), count.index) }"
}

resource "gzip_me" "dns_conf" {
  input = "${ var.dns_conf }"
}

resource "gzip_me" "dns_dhcp" {
  input = "${ var.dns_dhcp }"
}






resource "gzip_me" "kubelet" {
  count = "${ var.master_node_count }"
  input = "${ element(data.template_file.kubelet.*.rendered, count.index) }"
}

data "template_file" "kubelet" {
  count = "${ var.master_node_count }"
  template = "${ file( "${ path.module }/kubelet" )}"
  vars {

    cloud_provider = "${ var.cloud_provider }"
    cloud_config = "${ var.cloud_config }"
    dns_service_ip = "${ var.dns_service_ip }"
    cluster_domain = "${ var.cluster_domain }"

  }
}





resource "gzip_me" "kubelet_kubeconfig" {
  input = "${ data.template_file.kubelet_kubeconfig.rendered }"
}

data "template_file" "kubelet_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"
  vars {
    cluster = "certificate-authority: /etc/srv/kubernetes/pki/ca-certificates.crt \n    server: https://127.0.0.1"
    user = "kubelet"
    name = "service-account-context"
    user_authentication = "client-certificate: /etc/srv/kubernetes/pki/master.crt \n    client-key: /etc/srv/kubernetes/pki/master.key"
  }
}





resource "gzip_me" "etcd" {
  count = "${ var.master_node_count }"
  input = "${ element(data.template_file.etcd.*.rendered, count.index) }"
}

data "template_file" "etcd" {
  count = "${ var.master_node_count }"
  template = "${ file( "${ path.module }/etcd.yml" )}"
  vars {
    name = "${ var.name }"
    node = "${ var.name }-master-${ count.index +1 }"
    etcd_image = "${ var.etcd_image }"
    etcd_tag = "${ var.etcd_tag }"
    etcd_discovery = "${ var.etcd_discovery }"

  }
}





# resource "gzip_me" "etcd_events" {
#   count = "${ var.master_node_count }"
#   input = "${ element(data.template_file.etcd_events.*.rendered, count.index) }"
# }

# data "template_file" "etcd_events" {
#   count = "${ var.master_node_count }"
#   template = "${ file( "${ path.module }/etcd-events.yml" )}"
#   vars {
#     name = "${ var.name }"
#     node = "${ var.name }-worker-${ count.index +1 }"
#     etcd_image = "${ var.etcd_image }"
#     etcd_tag = "${ var.etcd_tag }"
#     etcd_discovery = "${ var.etcd_discovery }"
#   }
# }





resource "gzip_me" "kube_apiserver" {
  count = "${ var.master_node_count }"
  input = "${ element(data.template_file.kube_apiserver.*.rendered, count.index) }"
}

data "template_file" "kube_apiserver" {
  count = "${ var.master_node_count }"
  template = "${ file( "${ path.module }/kube-apiserver.yml" )}"
  vars {
    kube_apiserver_image = "${ var.kube_apiserver_image }"
    kube_apiserver_tag = "${ var.kube_apiserver_tag }"
    etcd_endpoint = "${ var.etcd_endpoint }"
    service_cidr = "${ var.service_cidr }"
    master_node_count = "${ var.master_node_count }"
    cloud_provider = "${ var.cloud_provider }"
    cloud_config = "${ var.cloud_config }"
  }
}





resource "gzip_me" "kube_controller_manager" {
  input = "${ data.template_file.kube_controller_manager.rendered }"
}

data "template_file" "kube_controller_manager" {
  template = "${ file( "${ path.module }/kube-controller-manager.yml" )}"
  vars {
    kube_controller_manager_image = "${ var.kube_controller_manager_image }"
    kube_controller_manager_tag = "${ var.kube_controller_manager_tag }"
    pod_cidr = "${ var.pod_cidr }"
    service_cidr = "${ var.service_cidr }"
    cluster_name = "${ var.cluster_name }"
    cloud_provider = "${ var.cloud_provider }"
    cloud_config = "${ var.cloud_config }"
  }
}





resource "gzip_me" "kube_controller_manager_kubeconfig" {
  input = "${ data.template_file.kube_controller_manager_kubeconfig.rendered }"
}

data "template_file" "kube_controller_manager_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"
  vars {
    cluster = "certificate-authority: /etc/srv/kubernetes/pki/ca-certificates.crt \n    server: https://127.0.0.1"
    user = "kube-controller-manager"
    name = "service-account-context"
    user_authentication = "client-certificate: /etc/srv/kubernetes/pki/master.crt \n    client-key: /etc/srv/kubernetes/pki/master.key"
  }
}




resource "gzip_me" "kube_scheduler" {
  input = "${ data.template_file.kube_scheduler.rendered }"
}

data "template_file" "kube_scheduler" {
  template = "${ file( "${ path.module }/kube-scheduler.yml" )}"
  vars {
    kube_scheduler_image = "${ var.kube_scheduler_image }"
    kube_scheduler_tag = "${ var.kube_scheduler_tag }"
  }
}





resource "gzip_me" "kube_scheduler_kubeconfig" {
  input = "${ data.template_file.kube_scheduler_kubeconfig.rendered }"
}

data "template_file" "kube_scheduler_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"
  vars {
    cluster = "certificate-authority: /etc/srv/kubernetes/pki/ca-certificates.crt \n    server: https://127.0.0.1"
    user = "kube-scheduler"
    name = "service-account-context"
    user_authentication = "client-certificate: /etc/srv/kubernetes/pki/master.crt \n    client-key: /etc/srv/kubernetes/pki/master.key"
  }
}





resource "gzip_me" "kube_proxy" {
  count = "${ var.master_node_count}"
  input = "${ element(data.template_file.kube-proxy.*.rendered, count.index) }"
}

data "template_file" "kube-proxy" {
  count = "${ var.master_node_count }"
  template = "${ file( "${ path.module }/kube-proxy.yml" )}"

  vars {
    pod_cidr = "${ var.pod_cidr }"
    kube_proxy_image = "${ var.kube_proxy_image }"
    kube_proxy_tag = "${ var.kube_proxy_tag }"
  }
}





resource "gzip_me" "proxy_kubeconfig" {
  input = "${ data.template_file.proxy_kubeconfig.rendered }"
}

data "template_file" "proxy_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"

  vars {
    cluster = "certificate-authority: /etc/srv/kubernetes/pki/ca-certificates.crt \n    server: https://127.0.0.1"
    user = "kube-proxy"
    name = "service-account-context"
    user_authentication = "client-certificate: /etc/srv/kubernetes/pki/master.crt \n    client-key: /etc/srv/kubernetes/pki/master.key"
  }
}





data "template_file" "master" {
  count = "${ var.master_node_count }"
  template = "${ file( "${ path.module }/master.yml" )}"

  vars {
    kubelet_artifact = "${ var.kubelet_artifact }"
    cni_artifact = "${ var.cni_artifact }"
    kubelet = "${ element(gzip_me.kubelet.*.output, count.index) }"
    kubelet_kubeconfig = "${ gzip_me.kubelet_kubeconfig.output }"
    etcd = "${ element(gzip_me.etcd.*.output, count.index) }"
    # etcd_events = "${ element(gzip_me.etcd_events.*.output, count.index) }"
    kube_apiserver = "${ element(gzip_me.kube_apiserver.*.output, count.index) }"
    kube_scheduler = "${ gzip_me.kube_scheduler.output }"
    kube_scheduler_kubeconfig = "${ gzip_me.kube_scheduler_kubeconfig.output }"
    kube_controller_manager = "${ gzip_me.kube_controller_manager.output }"
    kube_controller_manager_kubeconfig = "${ gzip_me.kube_controller_manager_kubeconfig.output }"
    kube_proxy = "${ element(gzip_me.kube_proxy.*.output, count.index) }"
    proxy_kubeconfig = "${ gzip_me.proxy_kubeconfig.output }"
    ca = "${ gzip_me.ca.output }"
    ca_key = "${ gzip_me.ca_key.output }"
    master = "${ element(gzip_me.master.*.output, count.index) }"
    master_key = "${ element(gzip_me.master_key.*.output, count.index) }"
    cloud_config_file = "${ base64gzip(var.cloud_config_file) }"
    dns_conf = "${ gzip_me.dns_conf.output }"
    dns_dhcp = "${ gzip_me.dns_dhcp.output }"
    name = "${ var.name }"

  }
}

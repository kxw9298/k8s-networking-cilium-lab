resource "google_project_service" "apis" {
  for_each = toset(["compute.googleapis.com", "container.googleapis.com"])

  service            = each.value
  disable_on_destroy = false
}

# VPC-native networking: nodes, pods and Services each get their own range.
resource "google_compute_network" "gke" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "gke" {
  name          = "${var.name}-subnet"
  region        = var.region
  network       = google_compute_network.gke.id
  ip_cidr_range = "10.20.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.24.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.28.0.0/20"
  }
}

# Least-privilege node identity instead of the Compute Engine default account.
resource "google_service_account" "nodes" {
  account_id   = "${var.name}-nodes"
  display_name = "${var.name} GKE nodes"
}

resource "google_project_iam_member" "nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "dpv2" {
  name     = var.name
  location = var.zone

  network    = google_compute_network.gke.id
  subnetwork = google_compute_subnetwork.gke.id

  # GKE Dataplane V2: Google-managed Cilium (the anetd DaemonSet) with eBPF
  # service load balancing and network policy instead of kube-proxy/iptables.
  datapath_provider = "ADVANCED_DATAPATH"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  # Turns on Dataplane V2 metrics and the managed Hubble relay.
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  # Lab cluster: allow terraform destroy.
  deletion_protection = false

  depends_on = [google_project_service.apis]
}

resource "google_container_node_pool" "default" {
  name       = "default"
  cluster    = google_container_cluster.dpv2.name
  location   = var.zone
  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = 50
    spot            = var.spot
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  depends_on = [google_project_iam_member.nodes]
}

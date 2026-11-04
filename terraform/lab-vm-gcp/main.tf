locals {
  apis = concat(
    ["compute.googleapis.com", "iap.googleapis.com"],
    var.billing_account_id != "" ? ["billingbudgets.googleapis.com"] : []
  )

  # Google's IAP TCP forwarding range: SSH arrives only through IAP unless
  # ssh_source_ranges adds more.
  iap_range = "35.235.240.0/20"
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  service            = each.value
  disable_on_destroy = false
}

# Dedicated network so the lab never touches the project's default VPC.
# 192.168.x avoids overlap with kind (10.244.0.0/16) and Cilium's default
# cluster-pool range (10.0.0.0/8).
resource "google_compute_network" "lab" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "lab" {
  name          = "${var.name}-subnet"
  region        = var.region
  network       = google_compute_network.lab.id
  ip_cidr_range = "192.168.10.0/24"
}

resource "google_compute_firewall" "ssh_iap" {
  name          = "${var.name}-allow-ssh-iap"
  network       = google_compute_network.lab.name
  direction     = "INGRESS"
  source_ranges = [local.iap_range]
  target_tags   = [var.name]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "ssh_direct" {
  count = length(var.ssh_source_ranges) > 0 ? 1 : 0

  name          = "${var.name}-allow-ssh-direct"
  network       = google_compute_network.lab.name
  direction     = "INGRESS"
  source_ranges = var.ssh_source_ranges
  target_tags   = [var.name]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "lab" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = [var.name]
  labels       = { purpose = "k8s-networking-lab" }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.lab.id

    # Ephemeral public IP for outbound downloads only; the firewall rules above
    # are the only inbound paths.
    access_config {}
  }

  scheduling {
    provisioning_model          = var.spot ? "SPOT" : "STANDARD"
    preemptible                 = var.spot
    automatic_restart           = !var.spot
    on_host_maintenance         = var.spot ? "TERMINATE" : "MIGRATE"
    instance_termination_action = var.spot ? "STOP" : null
  }

  # No service_account block: the VM gets no Google Cloud credentials, which the
  # lab does not need.

  desired_status            = var.running ? "RUNNING" : "TERMINATED"
  allow_stopping_for_update = true

  depends_on = [google_project_service.apis]
}

data "google_project" "this" {
  count = var.billing_account_id != "" ? 1 : 0
}

resource "google_billing_budget" "lab" {
  count = var.billing_account_id != "" ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "${var.name} monthly budget"

  budget_filter {
    projects = ["projects/${data.google_project.this[0].number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  depends_on = [google_project_service.apis]
}

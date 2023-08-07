provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "function_controller_name" {
  keepers = {
    function_name = var.function_name
  }

  byte_length = 8
}

resource "google_project_iam_member" "cloud-sql-editor-iam" {
  project = var.project_id
  role    = "roles/cloudsql.editor"
  member  = "serviceAccount:${google_service_account.instance_state_controller_service_account.email}"
}

resource "google_service_account" "instance_state_controller_service_account" {
  account_id   = var.function_name
  display_name = "Instance State Controller Service Account"
  description  = "service account to only operate as a Cloud Function that can mutate Cloud SQL instance states (or activation policy)"
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-${var.function_name}"
  location = var.region
}

resource "google_storage_bucket_object" "function_code" {
  name   = "${var.function_name}.zip"
  source = "${path.module}/dist/${var.function_name}.zip"
  bucket = google_storage_bucket.function_bucket.name
}

resource "google_cloudfunctions_function" "instance_state_controller" {
  name        = "instance-state-controller-${random_id.function_controller_name.hex}"
  description = "Control the on/off state of Cloud SQL instances (ideally non-production)"
  runtime     = "go120"

  available_memory_mb = 128
  max_instances       = 1

  service_account_email = google_service_account.instance_state_controller_service_account.email

  labels = {
    env = "dev"
  }

  source_archive_bucket        = google_storage_bucket.function_bucket.name
  source_archive_object        = google_storage_bucket_object.function_code.name
  trigger_http                 = true
  https_trigger_security_level = "SECURE_ALWAYS"
  timeout                      = 60
  entry_point                  = "HandleInstanceState"
}
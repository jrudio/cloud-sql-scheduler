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

resource "google_project_iam_member" "cloud-functions-invoker-iam" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.instance_state_scheduler_service_account.email}"
}

resource "google_service_account" "instance_state_scheduler_service_account" {
  account_id   = "${substr(var.function_name, 15, 0)}scheduler"
  display_name = "Instance State Scheduler Service Account"
  description  = "service account to invoke the Cloud Function"
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

resource "google_cloud_scheduler_job" "instance_state_scheduler_on" {
  name             = "${var.function_name}-scheduler-on"
  description      = "Schedules the target instance to turn on"
  schedule         = var.scheduler_time_on
  time_zone        = var.scheduler_time_zone
  attempt_deadline = "120s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.instance_state_controller.https_trigger_url
    body        = base64encode("{\"instanceName\":\"${var.instance_name}\",\"state\":\"on\"}")
    oidc_token {
      service_account_email = google_service_account.instance_state_scheduler_service_account.email
    }
  }

}

resource "google_cloud_scheduler_job" "instance_state_scheduler_off" {
  name             = "${var.function_name}-scheduler-off"
  description      = "Schedules the target instance to turn off"
  schedule         = var.scheduler_time_off
  time_zone        = var.scheduler_time_zone
  attempt_deadline = "120s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.instance_state_controller.https_trigger_url
    body        = base64encode("{\"instanceName\":\"${var.instance_name}\",\"state\":\"off\"}")
    oidc_token {
      service_account_email = google_service_account.instance_state_scheduler_service_account.email
    }
  }

}
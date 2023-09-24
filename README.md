## Description

Terraform module to turn on or off your Cloud SQL instance on a schedule for non-critical workloads saving money on unnecessary uptime

## Usage

```
module "cloud-sql-shutdown-scheduler" {
  source  = "jrudio/cloud-sql-shutdown-scheduler/google"
  version = "1.0.0"
  project_id = "<project-id>"
  region = "<cloud-sql-instance-region>"
  instance_name = "<cloud-sql-instance-name>"
}
```

## Components

Cloud Scheduler -> HTTP call -> Cloud Function -> HTTP call -> Cloud SQL

## Referenced Solution

https://cloud.google.com/blog/topics/developers-practitioners/lower-development-costs-schedule-cloud-sql-instances-start-and-stop
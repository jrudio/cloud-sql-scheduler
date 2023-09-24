variable "project_id" {
  type = string

  nullable = false
}

variable "region" {
  type = string

  nullable = true
}

variable "instance_name" {
  type = string

  nullable = true
}

variable "function_name" {
  type = string

  default = "instance-state-controller"
}

variable "scheduler_time_zone" {
  type = string

  default = "America/Los_Angeles"
}

variable "scheduler_time_on" {
  type = string

  description = "instance on - defaults to 8am PDT Monday through Friday - time in cron job expression"

  default = "00 8 * * 1-5"
}

variable "scheduler_time_off" {
  type = string

  description = "instance off - defaults to 6pm PDT  Monday through Friday - time in cron job expression"

  default = "00 8 * * 1-5"
}
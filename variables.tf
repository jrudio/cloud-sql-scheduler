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
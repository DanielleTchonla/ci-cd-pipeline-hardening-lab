variable "cluster_name" {}
variable "node_group_name" {}
variable "node_role_arn" {}
variable "subnet_ids" {
  type = list(string)
}

variable "instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 1
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}

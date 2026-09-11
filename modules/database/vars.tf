variable "subnet_id" {
  type        = string
  description = "The subnet to deploy this EC2 instance to"
  nullable    = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of security groups to be applied to this EC2 instance"
  nullable    = false
}

variable "environment" {
  type        = string
  description = "The environment for the resources"
}
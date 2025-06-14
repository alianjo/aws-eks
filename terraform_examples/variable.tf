variable "instance_type" {
  type        = string
  description = "The type of the instance"
}

variable "instance_name" {
  type        = string
  description = "The name of the instance"
}

variable "ami" {
  type        = string
  description = "The AMI to use for the instance"
}

variable "region" {
  type        = string
  description = "The region to use for the instance"
}


variable "key_name" {
  type        = string
  description = "The key name to use for the instance"
}

variable "sg_name" {
  type        = string
  description = "The security group name to use for the instance"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to use for the instance"
}

variable "backend_key" {
  type        = string
  description = "The key to use for the backend"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "network_name" {
  type = string
  default = "trace"
}

variable "subnet_params" {
  type = map(object({
    vnet = string
    cidr = string
  }))
}

variable "supernet" {
  type = string
}
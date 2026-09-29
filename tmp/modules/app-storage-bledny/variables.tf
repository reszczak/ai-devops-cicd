variable "uczestnik" {
  type = string
}

variable "blok" {
  default = "b1"
}

variable "region" {
  description = "Region AWS"
  type        = string
  default     = "eu-central-1"
}

variable "cidr_vpc" {
  description = "Zakres adresów dla VPC szkoleniowej"
  type        = string
  default     = "10.20.0.0/16"
}

variable "uczestnik" {
  description = "Twój identyfikator — wchodzi w nazwy zasobów"
  type        = string
}

variable "region" {
  description = "Region AWS"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_id" {
  description = "ID VPC, w której działa kolektor"
  type        = string
}

variable "cidr_vpc" {
  description = "Zakres adresów VPC, z którego kolektor przyjmuje syslog"
  type        = string
  default     = "10.20.0.0/16"
}

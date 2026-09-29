variable "uczestnik" {
  description = "Identyfikator uczestnika — małe litery i myślniki, wchodzi w nazwy zasobów"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.uczestnik))
    error_message = "Dozwolone są tylko małe litery, cyfry i myślniki, od 2 do 20 znaków."
  }
}

variable "blok" {
  description = "Numer bloku szkolenia — trafia do tagów, ułatwia sprzątanie"
  type        = string
  default     = "b1"
}

variable "region" {
  description = "Region AWS, w którym powstają zasoby"
  type        = string
  default     = "eu-central-1"
}

variable "cidr_vpc" {
  description = "Zakres adresów dla VPC szkoleniowej"
  type        = string
  default     = "10.20.0.0/16"
}

variable "key_name" {
  description = "Nombre del key pair existente"
  type        = string
  default     = "tu-keypair-existente"
}

variable "instance_count" {
  description = "Número de instancias y grupos"
  type        = number
  default     = 5
}

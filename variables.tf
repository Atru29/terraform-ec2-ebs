variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "AZ de la EC2 y de los volúmenes (un EBS solo se adjunta a instancias de su misma AZ)"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Tipo de instancia"
  type        = string
  default     = "t3.micro"
}

variable "data_volume_size" {
  description = "Tamaño en GiB del volumen de datos"
  type        = number
  default     = 1
}

variable "create_snapshot" {
  description = "Fase 2: crear el snapshot del volumen de datos y restaurarlo en un volumen independiente"
  type        = bool
  default     = false
}

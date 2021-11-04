variable "name" {
  type        = string
  default     = "sshkeygenexample"
  description = "Name for resources"
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "Azure Location of resources"
}

variable "function_app_dir" {
    type = string
    default = "../../Functions/published/latest-build.zip"
    description = "Directory where function app is located"
}
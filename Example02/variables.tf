variable "rgname" {
  type = string
  description = "VARIABLE NAME - RG Name"
}

variable "rglocation" {
  type = string
  description = "VARIABLE NAME - RG location"
}

variable "prefix" {
  type = string
  description = "used for defining the standard prefix"
}

variable "vnet_cicd_prefix" {
  type = string
  description = "This variable defines the address space for vnet"
}

variable "subnet1_cidr_prefix" {
    type = string
    description = "this variable defins address space for subnet"  
}
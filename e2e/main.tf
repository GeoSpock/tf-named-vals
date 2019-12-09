# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

variable "var1" {
  type = map(string)
  default = {
    key1 = "value1"
  }
  description = "This is the var1 variable"
}

variable "var2" {
  type = string
  default = "value"
  description = "This is the var2 variable"
}

variable "var3" {
  type = string
  default = "value"
}

variable "var4" {
  default = "value"
}

variable "var5" {
  default = "value"
}

locals {
  l1 = {
    a = "one"
    "b" = "${var.var2}${var.var3}-l1"
  }
  l2 = var.var4
  l3 = "test"
}

data "null_data_source" "values" {
  inputs = {
    a = var.var2
    b = local.l3
  }
}

resource "null_resource" "cluster" {
  triggers = {
    values = data.null_data_source.values.outputs.a
  }

  provisioner "local-exec" {
    command = "true"
  }
}

output "foo" {
  value = var.var1
}

output "bar" {
  sensitive = true
  description = "Secret"
  value = "${local.var1["key1"]}${var.var2}"
}

output "baz" {
  value = "value"
}


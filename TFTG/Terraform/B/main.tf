variable "name" {
    type = string
    default = "placeholder"
}

resource "local_file" "test" {
    content = "Hello, World! ${var.name}"

    filename = "/Users/johnsidford/Documents/TFTG/testB.txt"
}

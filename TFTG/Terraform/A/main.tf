resource "local_file" "test" {
    content = "Hello, World! A"

    filename = "/Users/johnsidford/Documents/TFTG/testA.txt"
}

output "output" {
    value = "this-is-an-output-from-A"
}   
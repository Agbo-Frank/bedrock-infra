resource "aws_dynamodb_table" "cart" {
  name         = "${var.title}-cart"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.title}-cart"
  }
}

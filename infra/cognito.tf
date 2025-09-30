variable "test_username" { default = "12345678901" }
variable "test_password" { default = "Abcd1234!" }  

resource "aws_cognito_user_pool" "pool" {
  name = "restaurante-user-pool"
  username_configuration { case_sensitive = false }
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "restaurante-api-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  generate_secret = false
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = var.test_username
  password     = var.test_password
  message_action = "SUPPRESS"
}

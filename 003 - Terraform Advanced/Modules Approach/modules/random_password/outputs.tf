output "result" {
  description = "Generated random password."
  value       = random_password.this.result
  sensitive   = true
}
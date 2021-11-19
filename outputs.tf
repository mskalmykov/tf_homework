output "instance_public_ip" {
  description = "Public IP address of the AppServer"
  value       = module.app_server.public_ip
}

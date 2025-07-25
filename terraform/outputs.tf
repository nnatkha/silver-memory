output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = module.app_service[*].lb_dns_name
}
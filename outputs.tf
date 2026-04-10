output "repo_name" {
  description = "Name of the created GitHub repository."
  value       = github_repository.this.name
}

output "repo_html_url" {
  description = "GitHub web URL for the repository."
  value       = github_repository.this.html_url
}

output "repo_ssh_clone_url" {
  description = "SSH clone URL for the repository."
  value       = github_repository.this.ssh_clone_url
}

output "workspace_dev_id" {
  description = "HCP Terraform workspace ID for the dev environment."
  value       = tfe_workspace.dev.id
}

output "workspace_main_id" {
  description = "HCP Terraform workspace ID for the main environment."
  value       = tfe_workspace.main.id
}

output "workspace_dev_url" {
  description = "HCP Terraform UI URL for the dev workspace."
  value       = "https://app.terraform.io/app/${var.tfe_organization}/workspaces/${tfe_workspace.dev.name}"
}

output "workspace_main_url" {
  description = "HCP Terraform UI URL for the main workspace."
  value       = "https://app.terraform.io/app/${var.tfe_organization}/workspaces/${tfe_workspace.main.name}"
}

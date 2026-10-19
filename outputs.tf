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
  value       = tfe_workspace.dev.html_url
}

output "workspace_main_url" {
  description = "HCP Terraform UI URL for the main workspace."
  value       = tfe_workspace.main.html_url
}

output "repo_urls" {
  description = "All URLs for the GitHub repository: web, SSH clone, and HTTPS clone."
  value = [
    github_repository.this.html_url,
    github_repository.this.ssh_clone_url,
    github_repository.this.http_clone_url,
  ]
}

output "workspace_urls" {
  description = "HCP Terraform UI URLs for both workspaces, main first then dev."
  value = [
    tfe_workspace.main.html_url,
    tfe_workspace.dev.html_url,
  ]
}

terraform {
  backend "s3" {
    bucket       = "flask-cicd-gitops-platform-tfstate-bd355f"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
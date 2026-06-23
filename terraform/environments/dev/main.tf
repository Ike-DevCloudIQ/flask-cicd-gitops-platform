module "network" {
  source = "../../modules/network"

  project_name              = var.project_name
  environment               = var.environment
  owner                     = var.owner
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidr        = var.public_subnet_cidr
  private_subnet_cidr       = var.private_subnet_cidr
  public_availability_zone  = var.public_availability_zone
  private_availability_zone = var.private_availability_zone
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
  vpc_id       = module.network.vpc_id
  your_ip_cidr = var.your_ip_cidr
}

module "compute" {
  source = "../../modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  owner             = var.owner
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  master_sg_id      = module.security.jenkins_master_sg_id
  slave_sg_id       = module.security.jenkins_slave_sg_id
  key_name          = var.key_name
  instance_type     = var.instance_type
}

module "notifications" {
  source = "../../modules/notifications"

  project_name       = var.project_name
  environment        = var.environment
  owner              = var.owner
  alert_email        = var.alert_email
  master_instance_id = module.compute.jenkins_master_instance_id
  slave_instance_id  = module.compute.jenkins_slave_instance_id
}
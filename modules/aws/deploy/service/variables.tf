# ========================
# General Deployment
# ========================
variable "project_name" {
  type        = string
  description = "Base name for ECS service, tasks, and resources"
}

variable "name" {
  type        = string
  description = "Base name for ECS service, tasks, and resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ECS tasks will run"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ECS service networking"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS task instances to run"
}

variable "capacity_provider_name" {
  type        = string
  default     = null
  description = "Optional ECS capacity provider name"
}

variable "enable_code_deploy" {
  type        = string
  default     = false
  description = "enable codedeploy app for bule green deploy"
}

variable "health_check_grace_period_seconds" {
  type = number
  default = null
  description = "Optional how much time to wait for running health check"
}

# ========================
# Load Balancer Config
# ========================
variable "load_balancer_config" {
  type = object({
    container_port              = number
    sg_id                       = string
    blue_target_group_arn       = string
    green_target_group_arn       = string
    blue_target_group_name      = string
    green_target_group_name     = string
    listener_arn                = string
  })
  default     = null
  description = "Load balancer configuration for ECS service and CodeDeploy (optional)"
}


# ========================
# ECS Task Config
# ========================
variable "task" {
  type = object({
    name          = string
    image_uri     = string
    essential     = bool
    cpu           = string
    memory        = string
    log_region   = string
    environment   = optional(list(object({
      name  = string
      value = string
    })))
    portMappings  = list(object({
      containerPort = number
      hostPort      = number
      protocol      = string
    }))
    command       = optional(list(string),[])
    task_role_arn = optional(string, null)
    mountPoints   = list(object({
      sourceVolume  = string
      containerPath = string
    }))
    volumes       = list(object({
      name            = string
      efs_id          = string
      access_point_id = string
    }))
  })
}

# ========================
# EFS
# ========================
variable "efs_arn" {
  type        = string
  description = "ARN of the EFS file system for ECS task volumes"
  default = null
}

# ========================
# ECS Cluster
# ========================
variable "ecs_cluster_id" {
  type        = string
  description = "ID of the ECS cluster where service will run"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

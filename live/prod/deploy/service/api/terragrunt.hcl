include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "service" {
  path   = find_in_parent_folders("service.hcl")
}

dependency "alb" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/compute/alb"

  mock_outputs = {
    id                 = "mock-alb-id"
    sg_id              = "mock-alb-sg-id"
    https_listener_arn = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
    blue_tg = {
      api = {
        name = "mock-tg-name"
        arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
      }
    }
    green_tg = {
      api = {
        name = "mock-tg-name"
        arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
      }
    }
  }
}

inputs = {
  name          = "api"
  desired_count = 1
  efs_arn       = dependency.jenkins_efs.outputs.arn

  capacity_provider_name = dependency.ecs.outputs.asg_cp["api"].name

  load_balancer_config = {
    sg_id                   = dependency.alb.outputs.sg_id
    listener_arn            = dependency.alb.outputs.https_listener_arn
    blue_target_group_name  = dependency.alb.outputs.blue_tg["api"].name
    green_target_group_name = dependency.alb.outputs.green_tg["api"].name
    blue_target_group_arn   = dependency.alb.outputs.blue_tg["api"].arn
    green_target_group_arn  = dependency.alb.outputs.green_tg["api"].arn
    container_port          = 8081
  }

  task = {
    name      = "api"
    cpu       = 256
    memory    = 512
    image_uri = ""
    essential = true
    log_region = include.env.locals.region
    portMappings = [
      {
        containerPort = 8081
        hostPort      = 8081
        protocol      = "tcp"
      }
    ]
  }
}
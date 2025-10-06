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
      jenkins = {
        name = "mock-tg-name"
        arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
      }
    }
    green_tg = {
      jenkins = {
        name = "mock-tg-name"
        arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
      }
    }
  }
}

dependency "jenkins_efs" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/storage/efs/jenkins"

  mock_outputs = {
    id   = "mock-efs-id"
    name = "mock-efs-name"
    arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
  }
}

inputs = {
  name          = "jenkins"
  desired_count = 1
  efs_arn       = dependency.jenkins_efs.outputs.arn

  capacity_provider_name = dependency.ecs.outputs.asg_cp["jenkins"].name

  load_balancer_config = {
    sg_id                   = dependency.alb.outputs.sg_id
    listener_arn            = dependency.alb.outputs.https_listener_arn
    blue_target_group_name  = dependency.alb.outputs.blue_tg["jenkins"].name
    green_target_group_name = dependency.alb.outputs.green_tg["jenkins"].name
    blue_target_group_arn   = dependency.alb.outputs.blue_tg["jenkins"].arn
    green_target_group_arn  = dependency.alb.outputs.green_tg["jenkins"].arn
    container_port          = 8080
  }

  task = {
    name      = "jenkins"
    cpu    = 1812
    memory = 800
    image_uri = "jenkins/jenkins:lts-alpine"
    essential = true
    log_region = include.env.locals.region
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "jenkins-data"
        containerPath = "/var/jenkins_home"
        readOnly      = false
      }
    ]
    volumes = [
      {
        name            = "jenkins-data"
        efs_id          = dependency.jenkins_efs.outputs.id
        access_point_id = dependency.jenkins_efs.outputs.access_points_ids["jenkins"].id
      }
    ]
  }
}
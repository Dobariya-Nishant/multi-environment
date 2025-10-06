include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/modules/aws/compute/ecs"
}

dependency "jenkins_asg" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/compute/asg/jenkins"

  mock_outputs = {
    id   = "jenkins-asg-id"
    name = "jenkins-asg-name"
    arn  = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:uuid:autoScalingGroupName/jenkins"
  }
}

inputs = {
  name = include.env.inputs.project_name
  auto_scaling_groups = {
    jenkins = {
      name            = "jenkins"
      arn             = dependency.jenkins_asg.outputs.arn
      target_capacity = 100
    }
  }
}
include "env" {
  path = find_in_parent_folders("env.hcl")
}

include {
  path = find_in_parent_folders("asg.hcl")
}

inputs = {
  name             = "jenkins"
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  instance_type    = "t3.micro"
  ebs_size         = 30
}
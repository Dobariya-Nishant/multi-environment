include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "ec2" {
  path   = find_in_parent_folders("ec2.hcl")
}

inputs = {
  name = "jenkins-agent"
  instance_type = "t3.micro"
  enable_public_ssh = true
  ebs_type = "gp2"
  ebs_size = 30
  associate_public_ip_address = true
}

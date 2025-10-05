include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/modules/aws/compute/ecs"
}

inputs = {
  name = include.env.inputs.project_name
  # auto_scaling_groups = {
   
  # }
}
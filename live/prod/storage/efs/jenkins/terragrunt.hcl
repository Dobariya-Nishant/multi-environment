include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include {
  path = find_in_parent_folders("efs.hcl")
}

inputs = {
  name = "jenkins"
  access_points = {
    jenkins = "/jenkins"
  }
}

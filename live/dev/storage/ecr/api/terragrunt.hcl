include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

terraform {
  source = "${get_path_to_repo_root()}/modules/aws/storage/ecr"
}

inputs = {
  name = "api"
}

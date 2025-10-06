include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_path_to_repo_root()}/modules/aws/iam/ci_cd_role"
}

inputs = {
  name = "activatree-github-action"
  project_name = "activatree"
  github_org = "Dobariya-Nishant"
  github_repo = "auth-service"
  environment = "global"
}

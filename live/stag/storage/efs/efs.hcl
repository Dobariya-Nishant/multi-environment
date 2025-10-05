terraform {
  source = "${get_path_to_repo_root()}/modules/aws/storage/efs"
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/network/vpc"

  mock_outputs = {
    id                 = "vpc-mock"
    public_subent_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subent_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

inputs = {
  vpc_id     = dependency.vpc.outputs.id
  subnet_ids = dependency.vpc.outputs.private_subent_ids
}

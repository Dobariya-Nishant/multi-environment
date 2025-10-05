terraform {
  source = "${get_path_to_repo_root()}/modules/aws/deploy/service"
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/network/vpc"

  mock_outputs = {
    id             = "vpc-mock"
    public_subent_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subent_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "ecs" {
  config_path = "${dirname(find_in_parent_folders("env.hcl"))}/compute/ecs"

  mock_outputs = {
    id   = "mock-cluster-id"
    name = "mock-cluster-name"
    arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
    asg_cp = {
      jenkins = {
        name = "mock-k-name"
        arn  = "arn:aws:autoscaling:us-east-1:123456789012:mock:uuid:mock/mock"
      }
    }
  }
}


inputs = {
  ecs_cluster_id   = dependency.ecs.outputs.id
  ecs_cluster_name = dependency.ecs.outputs.name

  vpc_id     = dependency.vpc.outputs.id
  subnet_ids = dependency.vpc.outputs.private_subent_ids
}

/*------------------------+
 | EC2 Instance Variables |
 +------------------------*/
instance_type = "t3.medium"
ami_id        = "ami-" # from packer build

/*-------------------+
 | General Variables |
 +-------------------*/
aws_region = "eu-central-1"

/*---------------------------+
 | Backend Storage Variables |
 +---------------------------*/
force_destroy_storage_backend = false

/*-----------------------------------+
 | StackGuardian Resources Variables |
 +-----------------------------------*/
stackguardian = {
  api_key  = "sgu_"
  org_name = ""
}

override_names = {
  global_prefix = "LOCAL_TF_SG_MODULE_TESTING"
  # runner_group_name = ""
  # connector_name    = ""
}

/*-----------------------+
 | EC2 Network Variables |
 +-----------------------*/
network = {
  vpc_id            = "vpc-"
  public_subnet_id  = "subnet-"
  private_subnet_id = "subnet-"
  # associate_public_ip           = false
  # create_network_infrastructure = false
}

/*-----------------------+
 | EC2 Storage Variables |
 +-----------------------*/
volume = {
  type                  = "gp3"
  size                  = 100
  delete_on_termination = false
}

/*------------------------------+
 | EC2 SSH Connection Variables |
 +------------------------------*/
firewall = {
  # ssh_key_name = "custom-key-pair"
  ssh_access_rules = {
    "custom" = "0.0.0.0/0"
  }
  additional_ingress_rules = {
    "k3s" = {
      port        = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  # ssh_public_key = <<EOT
  #   ssh-ed25519 ...
  # EOT
}

/*-----------------------------------+
 | Lambda Autoscaling Variables     |
 +-----------------------------------*/
scaling = {
  scale_out_cooldown_duration = 4
  scale_in_cooldown_duration  = 5
  scale_out_threshold         = 3
  scale_in_threshold          = 1
  scale_in_step               = 1
  scale_out_step              = 1
  min_runners                 = 1
}

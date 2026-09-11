# ----------------------------------------------------------------------------------------------------------
# PROVISION AWS EC2 INSTANCE FOR DATABASE
# ----------------------------------------------------------------------------------------------------------

resource "aws_instance" "ec2_instance_database" {
  # Localstack only supports certain AMIs, check this on AWS if it is erroring
  # See: https://docs.localstack.cloud/aws/services/ec2/#amis:~:text=At%20startup%2C%20LocalStack%20downloads%20the%20following%20AMIs%20that%20can%20be%20used%20to%20launch%20Dockerized%20instances.
  ami                    = var.environment == "local" ? "ami-024f768332f0" : data.aws_ami.al2026_arm.id
  instance_type          = "t4g.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = aws_key_pair.deployer.key_name
}

data "aws_ami" "al2026_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.18-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_key_pair" "deployer" {
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
  key_name   = "deployer"
}

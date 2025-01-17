
resource "aws_iam_role" "tfgoat-cluster" {
  name = "${local.prefix}-tfgoat-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "tfgoat-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.tfgoat-cluster.name
}

resource "aws_iam_role_policy_attachment" "tfgoat-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.tfgoat-cluster.name
}

resource "aws_security_group" "tfgoat-cluster" {
  name        = "${local.prefix}-tfgoat-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.tfgoat.id
  ingress {
    # [Shisho]: You can ignore this report by adding the following comment:
    # shisho: mark-as-intended aws-vpc-ensure-coarse-sg-ingress-is-intended
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group_rule" "tfgoat-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.tfgoat-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "tfgoat" {
  name     = "${local.prefix}-tfgoat-cluster"
  role_arn = aws_iam_role.tfgoat-cluster.arn
  vpc_config {
    security_group_ids = [aws_security_group.tfgoat-cluster.id]
    subnet_ids         = aws_subnet.tfgoat[*].id
    endpoint_public_access = false
  }
  depends_on = [
    aws_iam_role_policy_attachment.tfgoat-cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.tfgoat-cluster-AmazonEKSVPCResourceController,
  ]
  encryption_config {           
    provider {
      key_arn = aws_kms_key.example.arn
    }            
    resources = [ "secrets" ]
  }
  # [Shisho]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#enabled_cluster_log_types
  enabled_cluster_log_types = ["api", "authenticator", "audit", "scheduler", "controllerManager"]
}


# [Shisho]: See the following document:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "example" {
  description             = "example"
  deletion_window_in_days = 10
}



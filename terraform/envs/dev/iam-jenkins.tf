#############################################
# Jenkins EC2 IAM Role + Instance Profile
#############################################

data "aws_iam_policy_document" "jenkins_ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_ec2_role" {
  name               = "tc2-jenkins-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_ec2_assume_role.json
  tags               = var.tags
}

# Minimal-ish policy for pushing images to ECR + describing the EKS cluster
data "aws_iam_policy_document" "jenkins_ec2_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "jenkins_ec2_policy" {
  name   = "tc2-jenkins-ec2-policy"
  policy = data.aws_iam_policy_document.jenkins_ec2_policy.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "jenkins_ec2_attach" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_ec2_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_ec2_profile" {
  name = "tc2-jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2_role.name
  tags = var.tags
}

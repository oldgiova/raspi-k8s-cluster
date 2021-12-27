terraform {
    required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 3.27"
      }
    }

    required_version = ">= 1.1.2"
}

provider "aws" {
    profile = "default"
    region = "eu-south-1"
}


##### IAM user for Route 53
resource "aws_iam_user" "certbot" {
    name = var.certbot_username

    tags = {
        notes = var.tag_notes
    }
}

resource "aws_iam_user_policy" "certbot" {
    name = var.certbot_user_policy_name
    user = aws_iam_user.certbot.name

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "certbot-dns-route53 policy",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:GetChange"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect" : "Allow",
            "Action" : [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource" : [
                "arn:aws:route53:::hostedzone/${var.route53_hostedzone_id}"
            ]
        }
    ]
}

EOF
}
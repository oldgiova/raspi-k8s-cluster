variable "certbot_username" {
    type = string
    default = "oldgiova_certbot_user"
}

variable "tag_notes" {
    type = string
    default = "tag notes"
}

variable "certbot_user_policy_name" {
    type = string
    default = "certbot user policy name"
}

variable "route53_hostedzone_id" {
    type = string
    sensitive = true
}
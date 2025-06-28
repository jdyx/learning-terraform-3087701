module "qa" {
    source = "../modules/blog"

    environment = {
        name = "qa"
        network_prefix = "10.1"
    }

    asg_min = 1
    asg_max = 1

    ami_filter = {
        name = "bitnami-tomcat-8.5.99-0-linux-debian-11-x86_64-hvm-ebs-nami"
        owner = "979382823631" # Bitnami
    }
}

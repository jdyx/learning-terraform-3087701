module "qa" {
    source = "../modules/blog"

    environment = {
        name = "qa"
        network_prefix = "10.1"
    }

    asg_min = 1
    asg_max = 1

    ami_filter = {
        name = "bitnami-tomcat-10.1.29-0-linux-debian-12-x86_64-hvm-ebs-nami"
    }
}

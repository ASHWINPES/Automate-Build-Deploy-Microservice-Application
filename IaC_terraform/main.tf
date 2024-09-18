provider "aws" {
    region = "us-west-2"
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/10"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "advanced-devops-vpc"
    }
}

resource "aws_subset" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.vpc_id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_branch = true
    availability_zone = "us-west-2a"
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2b"
    tags = {
      Name = "private-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "main-igw"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        "Name" = "public-route-table"
    }
}

resource "aws_route_table_association" "public_subnet_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

module "eks" {
    source = "terraform-aws-modules/eks/aws"
    cluster_name = "advanced-eks-cluster"
    cluster_version = "1.24"
    vpc_id = aws_vpc.main_vpc.id
    subnets = [aws_subset.public_subnet.id, aws_subnet.private_subnet.id]

    node_groups = {
        eks_nodes = {
            desired_capacity = 3
            max_capacity = 5
            min_capacity = 2
            instance_type = "t3.medium"
            key_name = "your-key-pair"
            tags = {
                Name = "advanced-eks-node"
            }
        }
    }
}
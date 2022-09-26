resource "aws_vpc" "vishal_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vishal_dev"
  }
}

resource "aws_subnet" "vishal_subnet_public" {
  vpc_id                  = aws_vpc.vishal_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "vishal_dev-public"
  }

  depends_on = [
    aws_vpc.vishal_vpc
  ]
}

resource "aws_internet_gateway" "vishal_internet_gateway" {
  vpc_id = aws_vpc.vishal_vpc.id

  tags = {
    Name = "vishal_dev-igw"
  }

  depends_on = [
    aws_vpc.vishal_vpc
  ]
}

resource "aws_route_table" "vishal_public_rt" {
  vpc_id = aws_vpc.vishal_vpc.id
  tags = {
    Name = "vishal_dev_public_rt"
  }
  depends_on = [
    aws_vpc.vishal_vpc
  ]
}

resource "aws_route" "vishal_default_route" {
  route_table_id         = aws_route_table.vishal_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vishal_internet_gateway.id

  depends_on = [
    aws_route_table.vishal_public_rt,
    aws_internet_gateway.vishal_internet_gateway
  ]
}

resource "aws_route_table_association" "vishal_public_assoc" {
  subnet_id      = aws_subnet.vishal_subnet_public.id
  route_table_id = aws_route_table.vishal_public_rt.id
  depends_on = [
    aws_subnet.vishal_subnet_public,
    aws_route_table.vishal_public_rt
  ]
}

resource "aws_security_group" "vishal_sg" {
  name        = "vishal_dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.vishal_vpc.id

  ingress {
    description = "from my machine"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # This should be the ip address of your machine  or vpc
    #This is just for demo purpose and should not be used, as I'm opening my subnet to the outside world
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
    aws_vpc.vishal_vpc
  ]
}

resource "aws_key_pair" "vishal_auth" {
  key_name   = "vishalkey"
  public_key = file("~/.ssh/vishalkey.pub")
}

resource "aws_instance" "vishal_dev_node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.vishal_server_ami.id
  key_name = aws_key_pair.vishal_auth.key_name
  vpc_security_group_ids = [aws_security_group.vishal_sg.id]
  subnet_id              = aws_subnet.vishal_subnet_public.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }  

  tags = {
    Name = "vishal_dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("windows-ssh-config.tpl",{
        hostname = self.public_ip,
        user = "ubuntu",
        identityfile = "~/.ssh/vishalkey"
    })
    interpreter = ["Powershell", "-Command"]
  }

  depends_on = [
    aws_key_pair.vishal_auth,
    aws_vpc.vishal_vpc,
    aws_subnet.vishal_subnet_public
  ]
}
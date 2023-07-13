locals {

  security_groups = {
    data_db = {
      description = "Security group for database servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    
    }

    web_group = {
      description = "Security group for web servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http135 = {
          description = "Allow ingress from port 135"
          from_port       = 135
          to_port         = 135
          protocol        = "Any"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http139 = {
          description = "Allow ingress from port 139"
          from_port       = 139
          to_port         = 139
          protocol        = "Any"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        https443 = {
          description = "Allow ingress from port 443"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http445 = {
          description = "Allow ingress from port 445"
          from_port       = 445
          to_port         = 445
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        RDP3389 = {
          description = "Allow ingress from port 3389"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http5985 = {
          description = "Allow ingress from port 5985"
          from_port       = 5985
          to_port         = 5985
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http5986 = {
          description = "Allow ingress from port 5986"
          from_port       = 5986
          to_port         = 5986
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http9100 = {
          description = "Allow ingress from port 9100"
          from_port       = 9100
          to_port         = 9100
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http9172 = {
          description = "Allow ingress from port 9172"
          from_port       = 9172
          to_port         = 9172
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http9182 = {
          description = "Allow ingress from port 9182"
          from_port       = 9182
          to_port         = 9182
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http49152_65535 = {
          description = "Allow ingress from port 49152-65535"
          from_port       = 49152-65535
          to_port         = 49152-65535
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
  }
}

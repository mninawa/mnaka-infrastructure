locals { 
  common_tags = { 
    environment     = "${lower(var.ENV)}" 
    project         = "Project VPC ECS in Sandbox" 
    managedby       = "Paige Mkoko"
  } 
}
terraform {
  required_providers {
    stackguardian = {
      source = "StackGuardian/stackguardian"
      version = "1.0.0-rc3"
    }
  }
}

provider "stackguardian" {
  
  api_key = var.api_key                                  # Replace this with your API key(test wiothout it)
  org_name = var.org_name                                # Replace this with your organization name
  api_uri = "https://testapi.qa.stackguardian.io"        # Use testapi instead of production for testing
}
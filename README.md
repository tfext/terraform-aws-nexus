# terraform-aws-nexus

Deploys Sonatype Nexus to an AWS ECS cluster

## Docker Support

To enable Docker support:

1. Create Nexus Docker repositories:
  * Proxy
  * Hosted (HTTP port 5001)
  * Group (HTTP port 5000)
2. Set the `docker = true` input variable on your module configuration
3. Run `terraform apply`

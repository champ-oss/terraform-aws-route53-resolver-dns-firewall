data "aws_vpcs" "this" {
  tags = {
    purpose = "vega"
  }
}

module "this" {
  source             = "../../"
  vpc_id             = data.aws_vpcs.this.ids[0]
}
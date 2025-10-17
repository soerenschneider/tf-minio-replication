users = [
  {
    name = "test"
  }
]


buckets = [
  {
    name = "replicationtest"
    region = "dd"

    versioning = {
      enabled = true
    }

    replication = {
      site_a_endpoint       = "https://nas.dd.soeren.cloud:443"
      site_b_endpoint       = "https://nas.ez.soeren.cloud:443"
      region_site_a         = "dd"
      region_site_b         = "ez"
      user_name = "replication"
      mode      = "two-way"
    }

    lifecycle_rules = [
      {
        id      = "test"
        enabled = true
        noncurrent_expirations = [{
          days = 1
          newer_versions = 3
        }]
      }
    ]
  }
]



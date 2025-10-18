users = [
  {
    name = "test"
    host_nice_name = "nas-dd"
    buckets = {
      replicationtest = {
        read_paths  = ["/"]
        write_paths = ["/uploads"]
      }
    }
  }
]


buckets = [
  {
    name = "replicationtest"
    region = "dd"
    host_nice_name = "nas-dd"

    versioning = {
      enabled = true
    }

    replication = {
      site_a_endpoint       = "https://nas.dd.soeren.cloud:443"
      site_b_endpoint       = "https://nas.ez.soeren.cloud:443"
      region_site_a         = "dd"
      region_site_b         = "ez"
      site_b_nice_name      = "nas-ez"
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



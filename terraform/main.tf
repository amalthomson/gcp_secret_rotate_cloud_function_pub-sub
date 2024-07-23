# provider "google" {
#   project     = "static-website-hosting-429208"
#   region      = "us-central1"
#   credentials = file("/Users/office-ayatacommerce/Desktop/Keys/static-website-hosting-429208-bfd6442492b3.json")
# }

# # Copy package.json to ./dist
# resource "local_file" "package_json" {
#   content  = file("${path.module}/../src/package.json")
#   filename = "${path.module}/../dist/package.json"
# }

# # Create a zip of all contents in ./dist
# data "archive_file" "function_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/../dist"
#   output_path = "${path.module}/../function/rotate-secret-function.zip"

#   depends_on = [local_file.package_json]
# }

# # Create a Google Cloud Storage bucket
# resource "google_storage_bucket" "bucket" {
#   name     = "rotate-secret-function-bucket"
#   location = "US"
# }

# # Upload the zip file to Google Cloud Storage bucket
# resource "google_storage_bucket_object" "gcf-secret-rotation" {
#   name   = "gcf-secret-rotation.zip"
#   bucket = google_storage_bucket.bucket.name
#   source = data.archive_file.function_zip.output_path

#   depends_on = [data.archive_file.function_zip]
# }

# # Create a Google Cloud Function
# resource "google_cloudfunctions_function" "function" {
#   name        = "rotate-secret-function"
#   description = "Function to rotate secret every 2 minutes"
#   runtime     = "nodejs14"
#   entry_point = "rotateSecret"
#   source_archive_bucket = google_storage_bucket.bucket.name
#   source_archive_object = google_storage_bucket_object.gcf-secret-rotation.name
#   trigger_http = true
#   available_memory_mb   = 128
#   timeout               = 60

#   environment_variables = {
#     NODE_ENV = "production"
#   }

#   service_account_email = "pipeline-demo@static-website-hosting-429208.iam.gserviceaccount.com"

#   depends_on = [google_storage_bucket_object.gcf-secret-rotation]
# }

# # Create a Google Cloud Scheduler job
# resource "google_cloud_scheduler_job" "job" {
#   name             = "rotate-secret-scheduler"
#   description      = "Job to rotate secret every 2 minutes"
#   schedule         = "*/2 * * * *"  # Every 2 minutes
#   time_zone        = "Etc/UTC"

#   http_target {
#     http_method = "POST"
#     uri         = google_cloudfunctions_function.function.https_trigger_url
#     oidc_token {
#       service_account_email = google_cloudfunctions_function.function.service_account_email
#     }
#   }

#   depends_on = [google_cloudfunctions_function.function]
# }

provider "google" {
  project     = "static-website-hosting-429208"
  region      = "us-central1"
  credentials = file("/Users/office-ayatacommerce/Desktop/Keys/static-website-hosting-429208-bfd6442492b3.json")
}

# Copy package.json to ./dist
resource "local_file" "package_json" {
  content  = file("${path.module}/../src/package.json")
  filename = "${path.module}/../dist/package.json"
}

# Create a zip of all contents in ./dist
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../dist"
  output_path = "${path.module}/../function/rotate-secret-function.zip"
  depends_on  = [local_file.package_json]
}

# Create a Google Cloud Storage bucket
resource "google_storage_bucket" "bucket" {
  name     = "rotate-secret-function-bucket"
  location = "US"
}

# Upload the zip file to Google Cloud Storage bucket
resource "google_storage_bucket_object" "gcf-secret-rotation" {
  name       = "gcf-secret-rotation.zip"
  bucket     = google_storage_bucket.bucket.name
  source     = data.archive_file.function_zip.output_path
  depends_on = [data.archive_file.function_zip]
}

# Create a 2nd Gen Google Cloud Function
resource "google_cloudfunctions2_function" "function" {
  name        = "rotate-secret-function"
  description = "Function to rotate secret every 2 minutes"
  location    = "us-central1"

  build_config {
    runtime     = "nodejs16"
    entry_point = "rotateSecret"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.gcf-secret-rotation.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "128Mi"
    timeout_seconds    = 60
    environment_variables = {
      NODE_ENV = "production"
    }
    service_account_email = "pipeline-demo@static-website-hosting-429208.iam.gserviceaccount.com"
  }

  event_trigger {
    trigger_region = "us-central1"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.function_trigger.id
  }
}

# Create a Pub/Sub topic for the function trigger
resource "google_pubsub_topic" "function_trigger" {
  name = "rotate-secret-function-trigger"
}

# Create a Google Cloud Scheduler job
resource "google_cloud_scheduler_job" "job" {
  name        = "rotate-secret-scheduler"
  description = "Job to rotate secret every 2 minutes"
  schedule    = "*/2 * * * *"  # Every 2 minutes
  time_zone   = "Etc/UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.function_trigger.id
    data       = base64encode("Trigger function")
  }
}
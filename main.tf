# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_version = ">= 0.13"
  backend "gcs" {}
}

provider "archive" {}

provider "google" {
  version = "~> 3.0.0"
}

resource "random_string" "random_suffix" {
  length  = 4
  upper   = "false"
  special = "false"
}

resource "google_service_account" "main" {
  project      = var.project_id
  account_id   = "${var.environment}${random_string.random_suffix.result}"
  display_name = "${var.environment}${random_string.random_suffix.result}"
}

resource "google_project_service" "project_services" {
  project                    = var.project_id
  count                      = var.enable_apis ? length(var.activate_apis) : 0
  service                    = element(var.activate_apis, count.index)
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_dependent_services
}

resource "google_pubsub_topic" "api_enable_topic" {
  name       = "${var.environment}${random_string.random_suffix.result}"
  project    = var.project_id
  depends_on = [google_project_service.project_services]
}

resource "google_pubsub_topic_iam_binding" "publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.api_enable_topic.name
  role    = "roles/pubsub.publisher"
  members = [google_logging_organization_sink.api_sink.writer_identity]
}

resource "google_organization_iam_member" "binding" {
  org_id     = var.org_id
  role       = "roles/editor"
  member     = "serviceAccount:${google_service_account.main.email}"
  depends_on = [google_cloudfunctions_function.function]
}

resource "google_logging_organization_sink" "api_sink" {
  name             = "${var.environment}${random_string.random_suffix.result}"
  org_id           = var.org_id
  include_children = true
  destination      = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.api_enable_topic.name}"
  filter           = "(protoPayload.methodName:\"google.api.serviceusage\" AND protoPayload.methodName:EnableService) OR (protoPayload.methodName:\"google.api.servicemanagement\" AND protoPayload.methodName:ActivateServices)"
}

resource "google_cloudfunctions_function" "function" {
  project               = var.project_id
  region                = var.region
  name                  = "apiPolice"
  entry_point           = "apiPolice"
  labels = {
    my-label = "my-label-value"
  }
  runtime               = var.runtime
  service_account_email = google_service_account.main.email
  source_archive_bucket = google_storage_bucket.gcf_source_bucket.name
  source_archive_object = google_storage_bucket_object.gcf_zip_gcs_object.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.api_enable_topic.name

    failure_policy {
      retry = var.function_event_trigger_failure_policy_retry
    }
  }

  depends_on = [google_project_service.project_services]
}

resource "google_storage_bucket" "gcf_source_bucket" {
  name     = "${var.environment}${random_string.random_suffix.result}"
  location = var.region
  project  = var.project_id
}

resource "google_storage_bucket_object" "gcf_zip_gcs_object" {
  name   = var.environment
  bucket = google_storage_bucket.gcf_source_bucket.name
  source = data.archive_file.gcf_zip_file.output_path
}

data "template_file" "cf" {
  template = "${file("${path.module}/function_source/index.js.tftemplate")}"
  vars = {
    blockedList = "${jsonencode(var.blocked_apis_list)}"
  }
}

data "archive_file" "gcf_zip_file" {
  type        = "zip"
  output_path = "${path.module}/function_source/${var.environment}.zip"

  source {
    content  = "${data.template_file.cf.rendered}"
    filename = "index.js"
  }

  source {
    content  = "${file("${path.module}/function_source/package.json")}"
    filename = "package.json"
  }
}

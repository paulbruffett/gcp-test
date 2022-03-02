terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.9.0"
    }
  }
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "pbazure"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "gcp-data4"
    }
  }
}

variable "GOOGLE_CREDENTIALS" {
  type = string
}

variable "PROJECT_NUMBER" {
  type = number
}

provider "google" {
  credentials = var.GOOGLE_CREDENTIALS

  project = var.PROJECT_NUMBER
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_pubsub_topic" "arduino-telemetry" {
  name = "arduino-telemetry"
}

resource "google_cloudiot_registry" "arduino-registry" {
  name     = "arduino-registry"

  event_notification_configs {
    pubsub_topic_name = google_pubsub_topic.arduino-telemetry.id
    subfolder_matches = ""
  }

}

resource "google_bigquery_dataset" "sensordata" {
  dataset_id                  = "sensor_data"
  friendly_name               = "sensorreadings"
  location                    = "us-east1"

    access {
    role = "OWNER"
    user_by_email = "paulbruffett@gmail.com"
  }
}

resource "google_bigquery_table" "arduinoreadings" {
  dataset_id = google_bigquery_dataset.sensordata.dataset_id
  table_id   = "arduino"


  schema = <<EOF
[
  {
    "name": "timestamp",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "temp",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
  {
    "name": "humidity",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
  {
    "name": "pressure",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
    {
    "name": "illuminance",
    "type": "FLOAT",
    "mode": "NULLABLE"
  }
]
EOF

}

resource "google_storage_bucket" "gcs-temp" {
    name          = "pb-temp-gcs"
    location      = "US"
    force_destroy = true
}

resource "google_service_account" "dataflow" {
  account_id   = "dataflow"
}

resource "google_dataflow_job" "arduino-df" {
  name              = "arduino-dataflow"
  template_gcs_path = "gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery"
  temp_gcs_location = "gs://pb-temp-gcs/"
  parameters = {
    output_table_spec = google_bigquery_table.arduinoreadings.table_id
    input_topic = "projects/data4-342823/topics/arduino-telemetry"
  }
}

data "google_iam_policy" "editor" {
  binding {
    role = "roles/bigquery.dataEditor"

    members = [
      "serviceAccount:", google_service_account.dataflow.name,
    ]
  }
}

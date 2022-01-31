terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "pbazure"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "gcp-test"
    }
  }
}

variable "GOOGLE_CREDENTIALS" {
  type = string
}

provider "google" {
  credentials = var.GOOGLE_CREDENTIALS

  project = "9589616824"
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

resource "google_bigquery_dataset" "sensor-data" {
  dataset_id                  = "sensor_data"
  friendly_name               = "sensorreadings"
  location                    = "us-east1"

  access {
    role = "READER"
    special_group = "allAuthenticatedUsers"
  }

    access {
    role = "OWNER"
    user_by_email = "paulbruffett@gmail.com"
  }
}

resource "google_bigquery_table" "arduino_readings" {
  dataset_id = google_bigquery_dataset.sensor-data.dataset_id
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
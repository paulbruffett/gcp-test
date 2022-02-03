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
      name = "gcp-iot"
    }
  }
}

variable "GOOGLE_CREDENTIALS" {
  type = string
}

provider "google" {
  credentials = var.GOOGLE_CREDENTIALS

  project = "882038477912"
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


resource "google_service_account" "dataflow" {
  account_id   = "dataflow"
}

data "google_iam_policy" "editor" {
  binding {
    role = "roles/bigquery.dataEditor"

    members = [
      "serviceAccount:", google_service_account.dataflow.name,
    ]
  }
}


resource "google_dataflow_job" "arduinodataflow" {
    name = "arduino-dataflow1"
    template_gcs_path = "gs://dataflow-templates/latest/PubSub_to_BigQuery"
    temp_gcs_location = "gs://pbgsb/files"
    parameters = {
      inputTopic = google_pubsub_topic.arduino-telemetry.id
      outputTableSpec    = "data2-340001:sensor_data.arduino"
    }
    service_account_email = google_service_account.dataflow.email
    enable_streaming_engine = true
}
# Week 1: Introduction to Docker and Terraform

Data Engineering is the design and development of systems for collecting, storing and analyzing data at scale.

# Docker
Docker is a software platform that allows you to build, test, and deploy applications quickly. Docker packages software into standardized units called containers that have everything the software needs to run including libraries, system tools, code, and runtime. Using Docker, you can quickly deploy and scale applications into any environment and know your code will run.

### 1.1. Build An Image with Dockerfile
Docker can build images automatically by reading the instructions from a Dockerfile. A Dockerfile is a text document that contains all the commands a user could call on the command line to assemble an image. This page describes the commands you can use in a Dockerfile.

```dockerfile
FROM python:3.9

RUN pip install pandas numpy

ENTRYPOINT [ "bash" ]
```

### 1.2. Docker Compose
Docker Compose is a tool for defining and running multi-container applications. It is the key to unlocking a streamlined and efficient development and deployment experience.

Compose simplifies the control of your entire application stack, making it easy to manage services, networks, and volumes in a single, comprehensible YAML configuration file. Then, with a single command, you create and start all the services from your configuration file.

Compose works in all environments; production, staging, development, testing, as well as CI workflows. It also has commands for managing the whole lifecycle of your application:

Start, stop, and rebuild services
View the status of running services
Stream the log output of running services
Run a one-off command on a service

```dockercompose
services:
  pgdatabase:
    image: postgres:13
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=root
      - POSTGRES_DB=ny_taxi
    volumes:
      - "./ny_taxi_postgres_data:/var/lib/postgresql/data:rw"
    ports:
      - "5432:5432"
  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=root
    ports:
      - "8080:80"
  pipeline:
    build: .
    depends_on:
      - pgdatabase
```

source: https://docs.docker.com


## 2.Running Docker with Postgres

1. Set up the Postgres container
This command is starting a PostgreSQL container with version 13, setting the database user, password, and name, mounting a volume for persistent data storage, and exposing port 5432 for connections to the database server.

```bash
docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v /Users/path/to/folder-pg/ny_taxi_postgres_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    --network=pg-network \
    --name=pg-database \
    postgres:13
```

or,

```bash
docker run -it \
  --env-file=.env \
  -v /Users/khalo/Data/DE/explore_de/01-docker-terraform/1_docker_postgres_sql/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name=pg-database \
  postgres:13
```

Create a file named .env in the same directory as your Docker command, and define your environment variables in it. For example:
```
POSTGRES_USER=root
POSTGRES_PASSWORD=root
POSTGRES_DB=ny_taxi
```

`--network=pg-network ` or docker network is important because it allows you to connect containers together. To create a network, use the following command:

```bash
docker network create pg-network #network name
```

2. Check the running containers

```bash
docker ps
```

3. Connect to the pg database with pgcli

```bash
 pgcli -h \
 localhost \ #--host
 -p 5432 \ #--port
 -u root \ #--username=root
  -d ny_taxi #--dbname=ny_taxi
```

## 3.Example Data Pipeline with Dockerfile
Dockerfile is a text file that specifies the instructions for building an image in the Docker container.

1. Create a Dockerfile
inside the Dockerfile:

```dockerfile
FROM python:3.9.1

RUN pip install pandas sqlalchemy psycopg2 wget

WORKDIR /app
COPY ingest_data.py ingest_data.py
COPY .env .env

ENTRYPOINT [ "python", "ingest_data.py" ]
```

2. Prepare the data pipeline with python script

Example:
```python
#!/usr/bin/env python
# coding: utf-8
import argparse
import pandas as pd
import wget
import pandas as pd
from time import time
from sqlalchemy import create_engine
import os


def main(params):
    user = os.environ.get('POSTGRES_USER')
    password = os.environ.get('POSTGRES_PASSWORD')
    host = os.environ.get('POSTGRES_HOST')
    port = os.environ.get('POSTGRES_PORT')
    db = os.environ.get('POSTGRES_DB')
    table_name = params.table_name
    url = params.url

    if url.endswith('.csv.gz'):
        csv_name = 'output.csv.gz'
    else:
        csv_name = 'output.csv'

    # Check if any required environment variable is missing or None
    if None in {user, password, host, port, db}:
        print("Error: One or more PostgreSQL connection parameters are missing.")
        return

    # Downloading the CSV file
    print('downloading the csv file...')
    wget.download(url, csv_name)

    df_iter = pd.read_csv(csv_name, compression='gzip', low_memory=False, iterator=True, chunksize=100000)
    df = next(df_iter)

    # Create a connection to the PostgreSQL database
    engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
    engine.connect()

    # get table schema
    print(pd.io.sql.get_schema(df, name=table_name, con=engine))
    # add columns
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')

    # insert data
    df.to_sql(name=table_name, con=engine, if_exists='append')

    # insert data in chunks
    while True:
        try:
            start = time()

            df = next(df_iter)

            df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
            df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

            df.to_sql(name=table_name, con=engine, if_exists='append')

            end = time()

            duration = end - start
            print(f'Inserted another chunk. It took {duration} seconds')

        except StopIteration:
            print("No more chunks to read. Exiting the loop.")
            break
    print('done..')
     # Delete the output file after successful ingestion
    os.remove(csv_name)

    print('Output file deleted.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest CSV data into Postgres')

    # Argument for table name, and url
    parser.add_argument('--table_name', help='name of the table where we will write the results to')
    parser.add_argument('--url', help='url of the csv file')
    args = parser.parse_args()

    # Run the main function
    main(args)

```

3. Build a Docker image

```bash
docker build -t <image_name> <path_to_dockerfile>
```

4. Run a Docker container

```bash
docker run -it \
    --network=pg-network \
    --env-file=.env \
    <image_name> \
    --table_name=yellow_taxi_trips \
    --url="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"
```

## 4. PostgreSQl+PGAdmin and Data Pipeline with Docker Compose (using two containers)

prepare .env file, which contains the following environment variables:
```env
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_HOST=pgdatabase
POSTGRES_PORT=5432
POSTGRES_DB=ny_taxi

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@admin.com
PGADMIN_DEFAULT_PASSWORD=root
```

1. Create a Docker Compose file for services
```dockercompose
services:
  pgdatabase:
    image: postgres:13
    env_file:
      - .env
    volumes:
      - "./ny_taxi_postgres_data:/var/lib/postgresql/data"
    ports:
      - "5432:5432"
    networks:
      - pg-network

  pgadmin:
    image: dpage/pgadmin4
    env_file:
      - .env
    ports:
      - "8080:80"

networks:
  pg-network:
    name: pg-network-1
    driver: bridge
```

2. Build a Docker image and start the containers

```bash
docker build -t <image_name> <path_to_dockerfile>
```

```bash
docker run -it \
    --network=pg-networ-1 \ #Connect to the pg-network-1
    --env-file=.env \
    taxi_ingest:v003 \
    --table_name=yellow_taxi_trips \
    --url="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"
```

3. Start the containers
```bash
docker compose up -d
```

4. Connect to PGAdmin
    - Go to http://localhost:8080
    - Login with username: admin and password: root
    - Set Up the server

5. Stop the containers
```bash
docker compose down
```

it is important to note that in order two containers to work together, they need to be in the same network. Hence, we created a new network named pg-network-1 and stated it in the Docker Compose file.

# 2.Terraform
Terraform is an infrastructure as code tool that lets you build, change, and version cloud and on-prem resources safely and efficiently.

How does Terraform work?
Terraform creates and manages resources on cloud platforms and other services through their application programming interfaces (APIs). Providers enable Terraform to work with virtually any platform or service with an accessible API.

source: https://developer.hashicorp.com/terraform?product_intent=terraform

![alt text](image.png)

Terraform simplify the process of keeping track of infrastructure as code. With infrastructure as code, it make it easy to reproduce the same infrastructure configuration in the future, easier to collaborate, and easier to remove.

## 1. Terraform Setup
    - Install Terraform
    - Create a new folder
    - Go to the folder
    - Create a new Terraform project
    - Initialize the project
        - terraform init
    - Validate the project
        - terraform validate
    - Plan the changes
        - terraform plan
    - Apply the changes
        - terraform apply
    - Destroy the changes
        - terraform destroy

## 2. Example Terraform: GCS Bucket

```terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
  credentials = file("./../keys/gcp_creds2.json")
  project     = "data-engineering-423323"
  region      = "us-central1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "de-project-4712-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
```

Then,
 - Run `terraform fmt` to format the Terraform code
 - Run `terraform init` to initialize the Terraform project
 - Run `terraform plan` to plan the Terraform changes
 - Run `terraform apply` to apply the Terraform changes

Later, to remove the infrastructure,
 - Run `terraform destroy` to destroy the Terraform changes

## 3. Example Terraform With Variables: GCS VM Instance

1. Create a Terraform file, `main.tf`.

```terraform
# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
  credentials = file("./../keys/gcp_creds2.json")
  project     = "data-engineering-423323"
  region      = "us-central1"
}

resource "google_compute_instance" "example" {
  boot_disk {
    auto_delete = var.boot_disk_auto_delete
    device_name = var.boot_disk_device_name

    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }

    mode = var.boot_disk_mode
  }

  can_ip_forward      = var.can_ip_forward
  deletion_protection = var.deletion_protection
  enable_display      = var.enable_display

  labels = var.labels

  machine_type = var.machine_type
  name         = var.name

  network_interface {
    access_config {
      network_tier = var.network_tier
    }

    queue_count = var.queue_count
    stack_type  = var.stack_type
    subnetwork  = var.subnetwork
  }

  scheduling {
    automatic_restart   = var.automatic_restart
    on_host_maintenance = var.on_host_maintenance
    preemptible         = var.preemptible
    provisioning_model  = var.provisioning_model
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  shielded_instance_config {
    enable_integrity_monitoring = var.enable_integrity_monitoring
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = var.enable_vtpm
  }

  zone = var.zone
}
```

2. Create a Terraform variables file, `variables.tf`.

```terraform
variable "boot_disk_auto_delete" {
  type    = bool
  default = true
}

variable "boot_disk_device_name" {
  type    = string
  default = "de-project01-20240515-100122"
}

variable "boot_disk_image" {
  type    = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240508"
  # detailed configuration parameters like these can provide attackers with valuable information about your infrastructure:
}

variable "boot_disk_size" {
  type    = number
  default = 20
}

variable "boot_disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "boot_disk_mode" {
  type    = string
  default = "READ_WRITE"
}

variable "can_ip_forward" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "enable_display" {
  type    = bool
  default = false
}

variable "labels" {
  type = map(string)
  default = {
    goog-ec-src = "vm_add-tf"
  }
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "name" {
  type    = string
  default = "de-project01-20240515-100122"
}

variable "network_tier" {
  type    = string
  default = "PREMIUM"
}

variable "queue_count" {
  type    = number
  default = 0
}

variable "stack_type" {
  type    = string
  default = "IPV4_ONLY"
}

variable "subnetwork" {
  type    = string
  default = "projects/<project name>/regions/us-central1/subnetworks/default"
  # This contains your project ID and specific network details, which can be used to target your project.
}

variable "automatic_restart" {
  type    = bool
  default = true
}

variable "on_host_maintenance" {
  type    = string
  default = "MIGRATE"
}

variable "preemptible" {
  type    = bool
  default = false
}

variable "provisioning_model" {
  type    = string
  default = "STANDARD"
}

variable "service_account_email" {
  type    = string
  default = "xxxxxx@developer.gserviceaccount.com" 
  #This email address can be used to identify your specific service account, which might be exploited to gain unauthorized access to your Google Cloud resources.
}

variable "service_account_scopes" {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

variable "enable_integrity_monitoring" {
  type    = bool
  default = true
}

variable "enable_secure_boot" {
  type    = bool
  default = false
}

variable "enable_vtpm" {
  type    = bool
  default = true
}

variable "zone" {
  type    = string
  default = "us-central1-b"
  # detailed configuration parameters like these can provide attackers with valuable information about your infrastructure:
}
```

## 4. Access GCS VM Instance

Once the infrastructure is created, you can access the VM instance using the following command:

example:

```bash
gcloud compute ssh --zone "us-central1-b" "de-project01-20240515-100122" --project "data-engineering-423323" --ssh-key-file <path_to_ssh_key>
```

or,

```bash
ssh -i ~/.ssh/<ssh_key> ubuntu@<external_ip>
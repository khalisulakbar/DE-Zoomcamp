# Introduction to Docker and Terraform

Data Engineering is the design and development of systems for collecting, storing and analyzing data at scale.

## 1.Docker
Docker is a software platform that allows you to build, test, and deploy applications quickly. Docker packages software into standardized units called containers that have everything the software needs to run including libraries, system tools, code, and runtime. Using Docker, you can quickly deploy and scale applications into any environment and know your code will run.

source: https://docs.docker.com

## 2.Example Data Pipeline with Dockerfile
Dockerfile is a text file that specifies the instructions for building an image in the Docker container.

1. Create a Dockerfile
inside the Dockerfile:

```dockerfile
FROM python:3.9.1

RUN pip install pandas sqlalchemy psycopg2 wget

WORKDIR /app
COPY ingest_data.py ingest_data.py 

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
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    url = params.url

    if url.endswith('.csv.gz'):
        csv_name = 'output.csv.gz'
    else:
        csv_name = 'output.csv'

    # URL of the CSV file
    url = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz'
        
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

            df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
            df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)

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

    # Argument for user, password, host, port, database name, table name, and url
    parser.add_argument('--user', help='username for postgres')
    parser.add_argument('--password', help='password for postgres')
    parser.add_argument('--host', help='host for postgres')
    parser.add_argument('--port', help='port for postgres')
    parser.add_argument('--db', help='database name for postgres')
    parser.add_argument('--table_name', help='name of the table where we will write the results to')
    parser.add_argument('--url', help='url of the csv file')
    args = parser.parse_args()

    # Run the main function
    main(args)
```

3. Build a Docker image

```bash
docker build -t <image_name> <url>
```

4. Run a Docker container

```bash
docker run -it <image_name>
```

### 2.Running Docker with Postgres

1. Set up the Postgres container
This command is starting a PostgreSQL container with version 13, setting the database user, password, and name, mounting a volume for persistent data storage, and exposing port 5432 for connections to the database server.

```bash
docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v /Users/path/to/folder-pg/ny_taxi_postgres_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:13
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



## 2.Terraform
Terraform is an infrastructure as code tool that lets you build, change, and version cloud and on-prem resources safely and efficiently.

How does Terraform work?
Terraform creates and manages resources on cloud platforms and other services through their application programming interfaces (APIs). Providers enable Terraform to work with virtually any platform or service with an accessible API.

source: https://developer.hashicorp.com/terraform?product_intent=terraform

![alt text](image.png)
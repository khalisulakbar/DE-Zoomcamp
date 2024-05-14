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

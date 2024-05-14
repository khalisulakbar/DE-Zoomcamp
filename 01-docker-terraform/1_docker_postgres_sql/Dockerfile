FROM python:3.9.1

RUN pip install pandas sqlalchemy psycopg2 wget

WORKDIR /app
COPY .env .env
COPY ingest_data_2.py ingest_data_2.py

ENTRYPOINT [ "python", "ingest_data_2.py" ]
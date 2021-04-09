import datetime
import os
import json
import random
import boto3

STREAM_NAME = os.environ["STREAM_NAME"]


def get_data():
    return {
        'EVENT_TIME': datetime.datetime.now().isoformat(),
        'TICKER': random.choice(['AAPL', 'AMZN', 'MSFT', 'INTC', 'TBV']),
        'PRICE': round(random.random() * 100, 2)}


def generate(stream_name, firehose_client):
    while True:
        data = get_data()
        print(data)
        firehose_client.put_record(
            DeliveryStreamName=stream_name,
            Record={'Data': json.dumps(data)},
        )


if __name__ == '__main__':
    generate(STREAM_NAME, boto3.client('firehose'))

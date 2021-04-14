import base64
import os
import unittest
from unittest import mock

import boto3
import moto
import moto.backends

ACCOUNT_ID = "fake-account-id"
STREAM_NAME = "stream1"

os.environ["STREAM_NAME"] = STREAM_NAME
os.environ["TWITTER_API_KEY"] = "fake-api-key"
os.environ["TWITTER_API_SECRET_KEY"] = "fake-api-secret-key"
os.environ["TWITTER_ACCESS_TOKEN"] = "fake-access-token"
os.environ["TWITTER_ACCESS_TOKEN_SECRET"] = "fake-access-token-secret"
os.environ["DEFAULT_BUFFER_SIZE"] = "2"

import producer


def create_s3_delivery_stream(client, stream_name):
    return client.create_delivery_stream(
        DeliveryStreamName=stream_name,
        DeliveryStreamType="DirectPut",
        ExtendedS3DestinationConfiguration={
            "RoleARN": "arn:aws:iam::{}:role/firehose_delivery_role".format(ACCOUNT_ID),
            "BucketARN": "arn:aws:s3:::fake-bucket",
            "Prefix": "myFolder/",
        },
    )


@moto.mock_kinesis
class ProducerTest(unittest.TestCase):
    def setUp(self):
        self.firehose_client = boto3.client("firehose", "us-east-1")
        self.stream_name = STREAM_NAME
        create_s3_delivery_stream(self.firehose_client, self.stream_name)
        self.listener = producer.MyStreamListener(self.stream_name, "us-east-1")

    def test_stream_exists(self):
        streams = self.firehose_client.list_delivery_streams()["DeliveryStreamNames"]
        self.assertEqual([STREAM_NAME], streams)

    def test_on_data(self):
        data = "{\"text\":\"my great tweet\"}"

        for _ in range(5):
            self.listener.on_data(data)

        firehose_records = moto.backends.get_backend("kinesis")["us-east-1"].delivery_streams[STREAM_NAME].records
        # One record is still in the buffer and hasn't been published
        self.assertEqual(4, len(firehose_records))
        self.assertEqual([data] * 4, [base64.b64decode(record.record_data).decode("utf-8") for record in firehose_records])

        # Close should flush any outstanding records
        self.listener.close()
        self.assertEqual(5, len(firehose_records))

    def test_on_data_retry(self):
        data = "{\"text\":\"my great tweet\"}"

        self.listener.on_data(data)

        all_records = [data] * 2
        error_records = [{"ErrorCode": "some error", "Data": rec} for rec in all_records]

        with mock.patch.object(
            self.listener,
            '_publish_to_kinesis',
            side_effect=[
                {"FailedPutCount": 2, "Records": error_records},
                {"FailedPutCount": 1, "Records": error_records[:2]},
                {"FailedPutCount": 0},
            ],
        ) as put_mock:
            self.listener.on_data(data)
            record_data = [{"Data": rec} for rec in all_records]
            put_mock.assert_has_calls([
                mock.call(record_data),
                mock.call(record_data[:2])
            ])
        

if __name__ == "__main__":
    unittest.main()


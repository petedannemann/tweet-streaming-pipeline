import base64
import unittest

import boto3
import moto
import moto.backends

import producer

ACCOUNT_ID = "fake-account-id"


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
        self.stream_name = "stream1"
        create_s3_delivery_stream(self.firehose_client, self.stream_name)
        self.listener = producer.MyStreamListener(self.stream_name)


    def test_on_data(self):
        data = "{\"text\":\"my great tweet\"}"
        self.listener.on_data(data)
        streams = self.firehose_client.list_delivery_streams()["DeliveryStreamNames"]
        self.assertEqual(["stream1"], streams)

        firehose_records = moto.backends.get_backend("kinesis")["us-east-1"].delivery_streams["stream1"].records
        self.assertEqual(1, len(firehose_records))
        self.assertEqual(data, base64.b64decode(firehose_records[0].record_data).decode("utf-8"))
        

if __name__ == "__main__":
    unittest.main()

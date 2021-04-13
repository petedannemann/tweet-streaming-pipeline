import datetime
import logging
import os
import json
import sys
import random
import time
import typing

import boto3
import tweepy

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

DEFAULT_BUFFER_SIZE = int(os.environ.get("DEFAULT_BUFFER_SIZE", "500"))
KINESIS_RETRY_COUNT = 10
KINESIS_RETRY_WAIT_IN_SEC = 0.1

STREAM_NAME = os.environ["STREAM_NAME"]
TWITTER_API_KEY = os.environ["TWITTER_API_KEY"]
TWITTER_API_SECRET_KEY = os.environ["TWITTER_API_SECRET_KEY"]
TWITTER_ACCESS_TOKEN = os.environ["TWITTER_ACCESS_TOKEN"]
TWITTER_ACCESS_TOKEN_SECRET = os.environ["TWITTER_ACCESS_TOKEN_SECRET"]


class MyStreamListener(tweepy.StreamListener):
    def __init__(
        self,
        stream_name: str,
        region: typing.Optional[str] = 'us-east-1',
    ) -> None:
        super().__init__()
        self.firehose_client = boto3.client('firehose', region)
        self.stream_name = stream_name
        self._buffer = []

    def _flush(
        self,
        kinesis_records: typing.List[typing.Dict[str, bytes]],
        retry_count: typing.Optional[int] = KINESIS_RETRY_COUNT,
    ) -> None:
        put_response = self.firehose_client.put_record_batch(
            DeliveryStreamName=self.stream_name,
            Records=kinesis_records,
        )

        failed_count = put_response['FailedPutCount']

        if failed_count > 0:
            if retry_count > 0:
                retry_kinesis_records = []
                for idx, record in enumerate(put_response['Records']):
                    if 'ErrorCode' in record:
                        retry_kinesis_records.append(kinesis_records[idx])
                time.sleep(KINESIS_RETRY_WAIT_IN_SEC * (KINESIS_RETRY_COUNT - retry_count + 1))
                self._flush(retry_kinesis_records, retry_count - 1)
            else:
                logger.error("Not able to put records after retries. Records: %s", put_response["Records"])
        logger.info("Flushed tweets to kinesis firehose")

    def on_data(self, data: bytes) -> bool:
        logger.debug("Received record: %s", json.dumps(data))
        self._buffer.append({'Data': data})

        if len(self._buffer) >= DEFAULT_BUFFER_SIZE:
            self._flush(self._buffer)
            self._buffer = []

        return True

    def on_status(self, status: typing.Dict[str, str]) -> None:
        logger.info("Received status: %s", status.text)

    def on_error(self, status_code) -> bool:
        if status_code == 420:
            logging.warn("Rate limit exceeded.")
            return True

        logger.error("Got an error with status code: %i - restarting the stream", status_code)
        # returning False disconnects the stream
        return True


def main(stream_name: str) -> None:
    auth = tweepy.OAuthHandler(TWITTER_API_KEY, TWITTER_API_SECRET_KEY)
    auth.set_access_token(TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET)
    stream_listener = MyStreamListener(stream_name)

    while True:
        try:
            stream = tweepy.Stream(auth=auth, listener=stream_listener)
            stream.sample()
        except KeyboardInterrupt:
            logging.info("Killing streaming process...")
            try:
                sys.exit(0)
            except SystemExit:
                os._exit(0)
        except Exception as ex:
            logging.error("Stream would have died, caught exception", exc_info=ex)


if __name__ == '__main__':
    main(STREAM_NAME)

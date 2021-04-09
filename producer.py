import datetime
import logging
import os
import json
import random

import boto3
import tweepy

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

STREAM_NAME = os.environ["STREAM_NAME"]
TWITTER_API_KEY = os.environ["TWITTER_API_KEY"]
TWITTER_API_SECRET_KEY = os.environ["TWITTER_API_SECRET_KEY"]
TWITTER_ACCESS_TOKEN = os.environ["TWITTER_ACCESS_TOKEN"]
TWITTER_ACCESS_TOKEN_SECRET = os.environ["TWITTER_ACCESS_TOKEN_SECRET"]


class MyStreamListener(tweepy.StreamListener):
    def __init__(self, stream_name):
        super().__init__()
        self.firehose_client = boto3.client('firehose')
        self.stream_name = stream_name

    def on_data(self, data):
        # TODO: retry publishing here and handle errors
        self.firehose_client.put_record(
            DeliveryStreamName=self.stream_name,
            Record={'Data': data},
        )
        logger.info("Published tweet to kinesis firehose")
        logger.debug("Publishing record to the stream: %s", json.dumps(data))
        return True

    def on_status(self, status):
        logger.info("Received status: %s", status.text)

    def on_error(self, status_code):
        if status_code == 420:
            logging.warn("Rate limit exceeded.")
            # TODO: implement back off here to prevent disconnecting
            return True

        logger.error("Got an error with status code: %i - restarting the stream", status_code)
        # returning False in on_data disconnects the stream
        return True


def main(stream_name):
    auth = tweepy.OAuthHandler(TWITTER_API_KEY, TWITTER_API_SECRET_KEY)
    auth.set_access_token(TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET)
    stream_listener = MyStreamListener(stream_name)

    while True:
        try:
            stream = tweepy.Stream(auth=auth, listener=stream_listener)
            stream.filter(track=['python'])
        except Exception as ex:
            logging.error("Stream would have died, caught exception", exc_info=ex)


if __name__ == '__main__':
    main(STREAM_NAME)

import datetime
import os
import json
import random

import boto3
import tweepy

STREAM_NAME = os.environ["STREAM_NAME"]
TWITTER_API_KEY = os.environ["TWITTER_API_KEY"]
TWITTER_API_SECRET_KEY = os.environ["TWITTER_API_SECRET_KEY"]
TWITTER_ACCESS_TOKEN = os.environ["TWITTER_ACCESS_TOKEN"]
TWITTER_ACCESS_TOKEN_SECRET = os.environ["TWITTER_ACCESS_TOKEN_SECRET"]


class MyStreamListener(tweepy.StreamListener):
    def __init__(self, firehose_client, stream_name):
        super().__init__()
        self.firehose_client = firehose_client
        self.stream_name = stream_name

    def on_data(self, data):
        tweet = json.loads(data)
        self.firehose_client.put_record(
            DeliveryStreamName=self.stream_name,
            Record={'Data': tweet["text"]},
        )
        print("Publishing record to the stream: ", tweet)
        return True

    def on_status(self, status):
        print(status.text)

    def on_error(self, status_code):
        print("got an error with status code: ", status_code)
        if status_code == 420:
            #returning False in on_data disconnects the stream
            return False


def main(firehose_client, stream_name):
    auth = tweepy.OAuthHandler(TWITTER_API_KEY, TWITTER_API_SECRET_KEY)
    auth.set_access_token(TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET)
    stream_listener = MyStreamListener(firehose_client, stream_name)
    stream = tweepy.Stream(auth=auth, listener=stream_listener)
    stream.filter(track=['python'])


if __name__ == '__main__':
    main(boto3.client('firehose'), STREAM_NAME)

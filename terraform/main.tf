provider "aws" {
  region = "${var.region}"
}

data "aws_region" "default" {}

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket        = var.s3_bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "athena_results_bucket" {
  bucket        = var.athena_s3_bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group" {
  name = "/aws/kinesisfirehose/${var.kinesis_firehose_stream_name}"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream" {
  log_group_name = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
  name           = "S3Delivery"
}

data "aws_caller_identity" "current" {}

resource "aws_glue_catalog_database" "glue_catalog_database" {
  name = var.glue_catalog_database_name
}

resource "aws_glue_catalog_table" "glue_catalog_table" {
  name          = var.glue_catalog_table_name
  database_name = aws_glue_catalog_database.glue_catalog_database.name

  parameters = {
    "classification"      = "parquet"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    location      = "s3://${aws_s3_bucket.kinesis_firehose_stream_bucket.bucket}/${var.s3_prefix}/"

    ser_de_info {
      name                  = "JsonSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
        "explicit.null"        = false
      }
    }

    columns {
      name       = "created_at"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "id"
      parameters = {}
      type       = "bigint"
    }
    columns {
      name       = "id_str"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "text"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "source"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "truncated"
      parameters = {}
      type       = "boolean"
    }
    columns {
      name       = "in_reply_to_status_id"
      parameters = {}
      type       = "bigint"
    }
    columns {
      name       = "in_reply_to_status_id_str"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "in_reply_to_user_id"
      parameters = {}
      type       = "bigint"
    }
    columns {
      name       = "in_reply_to_user_id_str"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "in_reply_to_screen_name"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "user"
      parameters = {}
      type       = "struct<id:bigint,id_str:string,name:string,screen_name:string,location:string,url:string,description:string,translator_type:string,protected:boolean,verified:boolean,followers_count:int,friends_count:int,listed_count:int,favourites_count:int,statuses_count:int,created_at:string,utc_offset:string,time_zone:string,geo_enabled:boolean,lang:string,contributors_enabled:boolean,is_translator:boolean,profile_background_color:string,profile_background_image_url:string,profile_background_image_url_https:string,profile_background_tile:boolean,profile_link_color:string,profile_sidebar_border_color:string,profile_sidebar_fill_color:string,profile_text_color:string,profile_use_background_image:boolean,profile_image_url:string,profile_image_url_https:string,profile_banner_url:string,default_profile:boolean,default_profile_image:boolean,following:string,follow_request_sent:string,notifications:string>"
    }
    columns {
      name       = "geo"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "coordinates"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "place"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "contributors"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "quoted_status_id"
      parameters = {}
      type       = "bigint"
    }
    columns {
      name       = "quoted_status_id_str"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "quoted_status"
      parameters = {}
      type       = "struct<created_at:string,id:bigint,id_str:string,text:string,source:string,truncated:boolean,in_reply_to_status_id:string,in_reply_to_status_id_str:string,in_reply_to_user_id:string,in_reply_to_user_id_str:string,in_reply_to_screen_name:string,user:struct<id:bigint,id_str:string,name:string,screen_name:string,location:string,url:string,description:string,translator_type:string,protected:boolean,verified:boolean,followers_count:int,friends_count:int,listed_count:int,favourites_count:int,statuses_count:int,created_at:string,utc_offset:string,time_zone:string,geo_enabled:boolean,lang:string,contributors_enabled:boolean,is_translator:boolean,profile_background_color:string,profile_background_image_url:string,profile_background_image_url_https:string,profile_background_tile:boolean,profile_link_color:string,profile_sidebar_border_color:string,profile_sidebar_fill_color:string,profile_text_color:string,profile_use_background_image:boolean,profile_image_url:string,profile_image_url_https:string,profile_banner_url:string,default_profile:boolean,default_profile_image:boolean,following:string,follow_request_sent:string,notifications:string>,geo:string,coordinates:string,place:string,contributors:string,is_quote_status:boolean,extended_tweet:struct<full_text:string,display_text_range:array<int>,entities:struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<string>,symbols:array<string>>>,quote_count:int,reply_count:int,retweet_count:int,favorite_count:int,entities:struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<string>,symbols:array<string>,media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<thumb:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>,medium:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>>>>>,favorited:boolean,retweeted:boolean,possibly_sensitive:boolean,filter_level:string,lang:string,display_text_range:array<int>,extended_entities:struct<media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<thumb:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>,medium:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>>>>>>"
    }
    columns {
      name       = "quoted_status_permalink"
      parameters = {}
      type       = "struct<url:string,expanded:string,display:string>"
    }
    columns {
      name       = "is_quote_status"
      parameters = {}
      type       = "boolean"
    }
    columns {
      name       = "extended_tweet"
      parameters = {}
      type       = "struct<full_text:string,display_text_range:array<int>,entities:struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<struct<screen_name:string,name:string,id:bigint,id_str:string,indices:array<int>>>,symbols:array<string>,media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<thumb:struct<w:int,h:int,resize:string>,medium:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>>>>>,extended_entities:struct<media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<thumb:struct<w:int,h:int,resize:string>,medium:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>>>>>>"
    }
    columns {
      name       = "quote_count"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "reply_count"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "retweet_count"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "favorite_count"
      parameters = {}
      type       = "int"
    }
    columns {
      name       = "entities"
      parameters = {}
      type       = "struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<struct<screen_name:string,name:string,id:bigint,id_str:string,indices:array<int>>>,symbols:array<string>>"
    }
    columns {
      name       = "favorited"
      parameters = {}
      type       = "boolean"
    }
    columns {
      name       = "retweeted"
      parameters = {}
      type       = "boolean"
    }
    columns {
      name       = "filter_level"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "lang"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "timestamp_ms"
      parameters = {}
      type       = "string"
    }
    columns {
      name       = "retweeted_status"
      parameters = {}
      type       = "struct<created_at:string,id:bigint,id_str:string,text:string,source:string,truncated:boolean,in_reply_to_status_id:string,in_reply_to_status_id_str:string,in_reply_to_user_id:string,in_reply_to_user_id_str:string,in_reply_to_screen_name:string,user:struct<id:bigint,id_str:string,name:string,screen_name:string,location:string,url:string,description:string,translator_type:string,protected:boolean,verified:boolean,followers_count:int,friends_count:int,listed_count:int,favourites_count:int,statuses_count:int,created_at:string,utc_offset:string,time_zone:string,geo_enabled:boolean,lang:string,contributors_enabled:boolean,is_translator:boolean,profile_background_color:string,profile_background_image_url:string,profile_background_image_url_https:string,profile_background_tile:boolean,profile_link_color:string,profile_sidebar_border_color:string,profile_sidebar_fill_color:string,profile_text_color:string,profile_use_background_image:boolean,profile_image_url:string,profile_image_url_https:string,profile_banner_url:string,default_profile:boolean,default_profile_image:boolean,following:string,follow_request_sent:string,notifications:string>,geo:string,coordinates:string,place:string,contributors:string,is_quote_status:boolean,extended_tweet:struct<full_text:string,display_text_range:array<int>,entities:struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<struct<screen_name:string,name:string,id:bigint,id_str:string,indices:array<int>>>,symbols:array<string>,media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<medium:struct<w:int,h:int,resize:string>,thumb:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>>>>>,extended_entities:struct<media:array<struct<id:bigint,id_str:string,indices:array<int>,media_url:string,media_url_https:string,url:string,display_url:string,expanded_url:string,type:string,sizes:struct<medium:struct<w:int,h:int,resize:string>,thumb:struct<w:int,h:int,resize:string>,large:struct<w:int,h:int,resize:string>,small:struct<w:int,h:int,resize:string>>>>>>,quote_count:int,reply_count:int,retweet_count:int,favorite_count:int,entities:struct<hashtags:array<struct<text:string,indices:array<int>>>,urls:array<struct<url:string,expanded_url:string,display_url:string,indices:array<int>>>,user_mentions:array<string>,symbols:array<string>>,favorited:boolean,retweeted:boolean,possibly_sensitive:boolean,filter_level:string,lang:string,display_text_range:array<int>>"
    }
    columns {
      name       = "possibly_sensitive"
      parameters = {}
      type       = "boolean"
    }
    columns {
      name       = "display_text_range"
      parameters = {}
      type       = "array<int>"
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_stream" {
  name        = var.kinesis_firehose_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn    = aws_iam_role.kinesis_firehose_stream_role.arn
    bucket_arn  = aws_s3_bucket.kinesis_firehose_stream_bucket.arn
    buffer_size = 128
    prefix      = var.s3_prefix

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.glue_catalog_database.name
        table_name    = aws_glue_catalog_table.glue_catalog_table.name
        role_arn      = aws_iam_role.kinesis_firehose_stream_role.arn
      }
    }
  }
}

resource "aws_athena_workgroup" "this" {
  name = "athena_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/output/"
    }
  }
}

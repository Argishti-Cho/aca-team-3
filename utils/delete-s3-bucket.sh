#!/bin/bash


#remove bucket
 remove_bucket() {
    aws s3 rb s3://$1
 }

 remove_bucket

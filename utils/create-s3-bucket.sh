#!/bin/bash

# create bucket 

create_bucket() {
    aws s3 mb s3://$1
}

create_bucket


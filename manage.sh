#!/bin/bash

source ./utils/

if [[ $1 == "create" ]]; then
    create_vpc
elif [[ $1 == "delete" ]]; then
    delete_vpc
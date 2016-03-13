#!/bin/bash
cd `dirname $0`
mkdir -p ./data/db
mongod --config ./data/mongod.conf


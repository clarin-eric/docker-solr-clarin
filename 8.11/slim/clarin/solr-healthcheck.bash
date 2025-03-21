#!/bin/bash
curl -s --fail http://127.0.0.1:8983/solr/ > /dev/null ||
exit 1

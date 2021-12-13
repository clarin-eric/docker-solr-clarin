#!/bin/bash
curl -s --fail http://localhost:8983/solr/ > /dev/null ||
exit 1

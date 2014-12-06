#!/bin/bash

cd /vagrant/movies_unsorted
napi.sh --format subrip --charset UTF8 --cover --nfo --delete-orig *
cd /vagrant
node movies.js

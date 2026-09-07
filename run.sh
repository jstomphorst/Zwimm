#!/bin/bash

# Verwijder bestaande container indien aanwezig
docker rm -f zwimm-agent || true

# Bouw Docker-image
docker build -t zwimm-agent .

# Start de container
docker run -it zwimm-agent
#!/bin/bash



echo "[run.sh] Baking tasty pages..."
./baker/baker.py
echo "[run.sh] Listing pages..."
./baker/lister.py

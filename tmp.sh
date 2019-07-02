#!/bin/bash

if [ -f /*/Dockerfile ]; then
    echo "there's a file"
else
    echo "there's none"
fi

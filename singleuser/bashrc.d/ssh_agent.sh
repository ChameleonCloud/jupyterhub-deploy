#!/usr/bin/env bash

# Set up the SSH agent
eval $(ssh-agent)
ssh-add "/work/.ssh/id_rsa"

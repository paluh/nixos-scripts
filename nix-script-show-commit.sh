#!/usr/bin/env bash

nixos-version | awk -F. '{print $3}' | awk '{print $1}'


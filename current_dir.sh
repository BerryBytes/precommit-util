#!/bin/bash
set -e

if [ "${PWD##*/}" != "01cloud-githooks" ]; then
    printf "[!] Error: Please run this script from the 01cloud-githooks directory. \n"
    exit 1
fi
current_dir=$(pwd)
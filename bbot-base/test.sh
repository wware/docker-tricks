#!/bin/bash

source /python-sandbox/bin/activate
python -c 'from Crypto.Cipher import AES' || exit 1
python -c 'from setuptools import setup' || exit 1
python -c 'import lxml' || exit 1
python -c 'import sqlalchemy' || exit 1

echo "All good."
exit 0

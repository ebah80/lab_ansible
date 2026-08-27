#!/bin/bash
echo "inizio a lavorare"
openssl rand -hex 32 > /tmp/foo.txt
ls -l /tmp/foo.txt
rm -f /tmp/foo.txt
echo "ho finito"

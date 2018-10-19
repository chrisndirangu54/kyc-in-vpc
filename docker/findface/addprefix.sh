#!/bin/sh
while read x; do
  printf "%20s | %s\n" "SERVICENAME" "$x"
done

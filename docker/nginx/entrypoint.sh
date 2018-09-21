#!/bin/sh
set -e

envify() {
  if [ -n "$2" ]
  then
    envsubst "`env | awk -F = '{printf \" $$%s\", $$1}'`" < "$1" > "$2"
  else
    envsubst "`env | awk -F = '{printf \" $$%s\", $$1}'`" < "$1"
  fi
}

if [ -n "$S3_PATH_TO_API_KEYS" ]
then
  echo "loading api key from $S3_PATH_TO_API_KEYS"
  API_KEYS=$(aws s3 cp "s3://$S3_PATH_TO_API_KEYS" -)
  export $(echo "$API_KEYS" | xargs)
  # aws s3 cp $S3_PATH_TO_API_KEYS /etc/nginx/conf.d/template.conf
else
  echo "\$S3_PATH_TO_API_KEYS not set, did you mean for this API to be open to the internet?"
fi

# replaces too many thing (everything with a dollar sign)
# envsubst < /etc/nginx/conf.d/template.conf > /etc/nginx/nginx.conf

# source:
# https://github.com/docker-library/docs/issues/496#issuecomment-370452557

# COPY location.tmpl /etc/nginx/conf.d/template-location.conf

if [ -n "$API_KEY" ]
then
  echo "API_KEY is set"
else
  export API_KEY=""
fi

LOCATIONS=""

if [[ "$ENABLE_TRUEFACE_SPOOF" == "1" ]]
then
  echo "adding /location for TrueFace Spoof"
  export LOCATION_HOSTNAME="$HOST_TRUEFACE_SPOOF"
  export LOCATION_PORT="$PORT_TRUEFACE_SPOOF"
  LOCATION=$(envify /etc/nginx/conf.d/template-location.conf)
  LOCATIONS=$(echo "$LOCATIONS

$LOCATION
")
fi

if [[ "$ENABLE_TRUEFACE_DASH" == "1" ]]
then
  echo "adding /location for TrueFace dashboard"
  export LOCATION_HOSTNAME="$HOST_TRUEFACE_DASH"
  export LOCATION_PORT="$PORT_TRUEFACE_DASH"
  LOCATION=$(envify /etc/nginx/conf.d/template-location.conf)
  LOCATIONS=$(echo "$LOCATIONS

$LOCATION
")
fi

if [[ "$ENABLE_RANK_ONE" == "1" ]]
then
  echo "adding /location for RankOne"
  export LOCATION_HOSTNAME="$HOST_RANK_ONE"
  export LOCATION_PORT="$PORT_RANK_ONE"
  LOCATION=$(envify /etc/nginx/conf.d/template-location.conf)
  LOCATIONS=$(echo "$LOCATIONS

$LOCATION
")
fi

export LOCATIONS="$LOCATIONS"

envify /etc/nginx/conf.d/template-main.conf /etc/nginx/nginx.conf

# echo "NGINX CONF:"
# cat /etc/nginx/nginx.conf

nginx -g "daemon off;"

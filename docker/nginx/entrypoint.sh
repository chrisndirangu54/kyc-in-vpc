#!/bin/sh
set -e

envify() {
  if [[ "$2" ]]
  then
    envsubst "`env | awk -F = '{printf \" $$%s\", $$1}'`" < "$1" > "$2"
  else
    envsubst "`env | awk -F = '{printf \" $$%s\", $$1}'`" < "$1"
  fi
}

if [[ "$NGINX_ENV_PATH" ]] && [[ -f "$NGINX_ENV_PATH" ]]
then
  echo "loading api key from $NGINX_ENV_PATH"
  export $(cat "$NGINX_ENV_PATH" | xargs)
  # export $(aws s3 cp "s3://$NGINX_ENV_PATH" - | xargs)
  # aws s3 cp $NGINX_ENV_PATH /etc/nginx/conf.d/template.conf
else
  echo "\$NGINX_ENV_PATH not set or file doesn't exist, did you mean for this API to be open to the internet?"
fi

# replaces too many thing (everything with a dollar sign)
# envsubst < /etc/nginx/conf.d/template.conf > /etc/nginx/nginx.conf

# source:
# https://github.com/docker-library/docs/issues/496#issuecomment-370452557

# COPY location.tmpl /etc/nginx/conf.d/template-location.conf

if [[ "$API_KEY" ]]
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
  export TOKEN=""
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
  EXPORT TOKEN=""
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
  export TOKEN=""
  LOCATION=$(envify /etc/nginx/conf.d/template-location.conf)
  LOCATIONS=$(echo "$LOCATIONS

$LOCATION
")
fi

if [[ "$ENABLE_FINDFACE" == "1" ]]
then
  until [ -r /etc/nginx/discovery/findface.token ];
  do
    sleep 1s
  done
  echo "adding /location for FindFace"
  export LOCATION_HOSTNAME="$HOST_FINDFACE"
  export LOCATION_PORT="$PORT_FINDFACE"
  export TOKEN=$(cat /etc/nginx/discovery/findface.token)
  LOCATION=$(envify /etc/nginx/conf.d/template-location.conf)
  LOCATIONS=$(echo "$LOCATIONS

$LOCATION
")
fi

export LOCATIONS="$LOCATIONS"

envify /etc/nginx/conf.d/template-main.conf /etc/nginx/nginx.conf

#echo "NGINX CONF:"
#cat /etc/nginx/nginx.conf

nginx

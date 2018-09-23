FROM nginx:alpine

# RUN apk add -u --update py-pip && pip install awscli

RUN apk add --no-cache curl

ADD ./nginx.conf /etc/nginx/conf.d/template-main.conf
ADD ./location.tmpl /etc/nginx/conf.d/template-location.conf
ADD ./entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

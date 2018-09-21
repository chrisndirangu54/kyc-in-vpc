FROM nginx:alpine

RUN apk add -u --update py-pip && pip install awscli

ADD ./nginx.conf /etc/nginx/conf.d/template-main.conf
ADD ./location.tmpl /etc/nginx/conf.d/template-location.conf
ADD ./entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

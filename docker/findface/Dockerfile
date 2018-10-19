FROM ubuntu:16.04
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN apt-get update
RUN apt-get install -y mongodb-org

ADD findface-repo-2.6.0.deb /home/ubuntu/
ADD findface-data-face-apricot-320_2.6.0_amd64.deb /home/ubuntu/
ADD findface-data_2.6.0_amd64.deb /home/ubuntu/

RUN dpkg -i /home/ubuntu/findface-repo-2.6.0.deb
RUN apt-key add /var/findface-repo/public.key
RUN apt-key update
RUN dpkg -i /home/ubuntu/findface-data*

RUN apt-get update
RUN apt-get install ntls -y
ADD *.lic /ntech/license/

RUN apt-get update
RUN apt-get install python3-facenapi -y --allow-unauthenticated

RUN apt-get update
RUN apt-get install findface-extraction-api -y --allow-unauthenticated 

RUN rm -f /home/ubuntu/*.deb

RUN apt-get clean && apt-get update && apt-get install -y runit python3-pip psmisc curl

RUN python3 -m pip install tornadostreamform==0.1.1
RUN curl -L https://github.com/peterbourgon/runsvinit/releases/download/v2.0.0/runsvinit-linux-amd64.tgz | tar -C / -xzv
RUN findface-facenapi --config-template > /etc/findface-facenapi.ini
RUN findface-extraction-api -models-model-instances=0 -models-facen=apricot_320 -models-gender= -models-age= -models-emotions= -config-template > /etc/findface-extraction-api.ini

ADD mongod.conf /etc/mongod.conf

ADD runit-extraction-api /etc/service/extraction-api/run
ADD runit-facenapi /etc/service/facenapi/run
ADD runit-mongo /etc/service/mongo/run
ADD runit-ntls /etc/service/ntls/run


ADD addprefix.sh /addprefix.sh
RUN for x in /etc/service/*; do mkdir -p "$x/log"; sed 's/SERVICENAME/'"$(basename -- "$x")"'/g' < /addprefix.sh > "$x/log/run"; done
RUN rm -f /addprefix.sh
RUN chmod +x /runsvinit /etc/service/*/run /etc/service/*/log/run

EXPOSE 8000

CMD ["/runsvinit"]


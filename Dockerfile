FROM ubuntu:24.04
ADD . /opt/
WORKDIR /opt
RUN apt-get update \
&& apt-get install -y nano sudo net-tools \
&& mkdir /usr/tmp
CMD ["./start-flexlm.sh"]
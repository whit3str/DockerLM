FROM ubuntu:24.04
ADD . /opt/
WORKDIR /opt
RUN apt-get update \
&& apt-get install -y nano sudo net-tools \
&& mkdir /usr/tmp
EXPOSE 1700 1701
CMD ["./start-flexlm.sh"]
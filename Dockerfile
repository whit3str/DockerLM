FROM ubuntu:24.04
ADD . /opt/
WORKDIR /opt
EXPOSE 1700 1701
RUN apt-get update \
&& apt-get install -y nano sudo net-tools macchanger \
&& mkdir /usr/tmp
CMD ["./start-flexlm.sh"]
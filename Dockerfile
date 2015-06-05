FROM maven:3.2-jdk-7

RUN apt-get update && apt-get install -y \
       bzip2 \
       vim \
	   jq

ENV ITS_TOKEN SECRET

WORKDIR /root
ADD . /root/

CMD ["./travis.sh"]


FROM maven:3.2-jdk-7

# Install dependencies
RUN apt-get update && apt-get install -y \
  bzip2 \
  nodejs \
  npm \
  xvfb \
  vim \
  jq

RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install firefox 31
RUN (curl -SL http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/31.0/linux-x86_64/en-US/firefox-31.0.tar.bz2 | tar xj -C /opt) \
	&& ln -sf /opt/firefox/firefox /usr/bin/firefox

# Warmup maven cache with Sonarqube
RUN mkdir /tmp/sonarqube \
	&& cd /tmp/sonarqube \
	&& curl -sSL https://github.com/SonarSource/sonarqube/tarball/5.1.1 | tar zx --strip-components 1 \
	&& mvn install -Pdev -DskipTests \
	&& rm -Rf /tmp/sonarqube

ENV TESTS SONARQUBE_SNAPSHOT
ENV CI true
ENV TRAVIS true
ENV RAILS_ENV test
ENV PATH ~/.local/bin:$PATH

WORKDIR /root
CMD ["./travis.sh"]

ADD . ./

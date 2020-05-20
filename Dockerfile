FROM libis/teneo-ruby:latest

RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list \
    && apt-get update -qq \
    && apt-get -qqy upgrade \
    && apt-get install -qqy --no-install-recommends \
      mongodb-org \
      libchromaprint-dev \
      ffmpeg \
      libreoffice \
      imagemagick \
      ghostscript \
      fonts-liberation \
      clamav clamav-freshclam \
      python-2.7 python-pip python-setuptools python-wheel \
      unzip \
      default-jre \
      apt-transport-https software-properties-common \
    && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
    && apt-get update -qq \
    && apt-get install -qqy --no-install-recommends adoptopenjdk-8-hotspot \
    && apt-get clean \
    && rm -fr /var/cache/apt/archives/* \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp* \
    && truncate -s 0 /var/log/*log

# Select java version
RUN update-alternatives --set java  `update-alternatives --list java | grep adoptopenjdk-8-hotspot`
ENV JAVA_HOME=$(dirname ($dirname `update-alternatives --list java | grep adoptopenjdk-8-hotspot`))

# Install fido
RUN pip install opf-fido

# Install droid
RUN wget -q https://github.com/digital-preservation/droid/releases/download/droid-6.5/droid-binary-6.5-bin.zip \
    && unzip -qd /opt/droid droid-binary-6.5-bin.zip \
    && chmod 755 /opt/droid/droid.sh

# Set timezone
ARG TZ=Europe/Brussels
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create application user
ARG UID=2000
ARG GID=2000
ARG USERNAME=lias
ARG HOME_DIR=/${USERNAME}

RUN groupadd --gid ${GID} ${USERNAME}
RUN useradd --home-dir ${HOME_DIR} --create-home --no-log-init --uid ${UID} --gid ${GID} ${USERNAME}

# Switch to application user 
USER ${USERNAME}
WORKDIR ${HOME_DIR}

# Copy files into image
COPY --chown=${UID}:${GID} . .

# Start the menu
CMD ["ruby", "bin/main_menu.rb", "--config", "site.config.yml"]

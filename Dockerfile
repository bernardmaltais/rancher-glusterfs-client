FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common locales &&\
    update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales
RUN apt-get update && \
    apt-get install -y supervisor curl unzip pwgen inotify-tools dnsutils vim git wget python-pip sudo logrotate

# Add Python API for rancher-metadata
RUN pip install rancher_metadata

# Add logrotate setting
ADD assets/setup/logrotate-supervisor.conf /etc/logrotate.d/supervisord

# Add supervisor setting
ADD assets/setup/supervisor-cron.conf /etc/supervisor/conf.d/cron.conf

# Add syslog group for logrotate
RUN groupadd syslog

RUN apt-get update && \
    apt-get install -y nginx glusterfs-client dnsutils iputils-ping php5-fpm


ENV GLUSTER_VOL ranchervol
ENV GLUSTER_VOL_PATH /mnt/${GLUSTER_VOL}
ENV GLUSTER_PEER **ChangeMe**
ENV SERVICE_NAME gluster
ENV DEBUG 0

ENV HTTP_CLIENT_PORT 80
ENV GAME_SERVER_PORT 443
ENV HTTP_DOCUMENTROOT ${GLUSTER_VOL_PATH}/asteroids/documentroot

EXPOSE ${HTTP_CLIENT_PORT}
EXPOSE ${GAME_SERVER_PORT}

RUN mkdir -p /var/log/supervisor ${GLUSTER_VOL_PATH}
WORKDIR ${GLUSTER_VOL_PATH}

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./etc/nginx/sites-available/asteroids /etc/nginx/sites-available/asteroids

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm -f /etc/nginx/sites-enabled/default
RUN ln -fs /etc/nginx/sites-available/asteroids /etc/nginx/sites-enabled/asteroids
RUN perl -p -i -e "s/HTTP_CLIENT_PORT/${HTTP_CLIENT_PORT}/g" /etc/nginx/sites-enabled/asteroids
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/asteroids

RUN perl -p -i -e "s/GAME_SERVER_PORT/${GAME_SERVER_PORT}/g" /etc/supervisor/conf.d/supervisord.conf
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/local/bin/run.sh"]

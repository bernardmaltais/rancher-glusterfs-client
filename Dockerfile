FROM ubuntu:14.04

# Inspiration for php5 integration from from https://github.com/ftx/rancher-nginx-php-gluster-ha

# Install some usefull package
RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common locales &&\
    update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales
    
RUN add-apt-repository -y ppa:gluster/glusterfs-3.8 && \
    apt-get update && \
    apt-get install -y supervisor curl unzip pwgen inotify-tools dnsutils vim git wget \
                       python-pip sudo logrotate nginx glusterfs-client dnsutils iputils-ping php5-fpm

ENV GLUSTER_VOL ranchervol
ENV GLUSTER_VOL_PATH /mnt/${GLUSTER_VOL}
ENV SERVICE_NAME gluster
ENV DEBUG 0

ENV HTTP_CLIENT_PORT 80
ENV GAME_SERVER_PORT 443
ENV HTTP_SITE_NAME www
ENV HTTP_GIT_SRC https://github.com/bernardmaltais/demosite.git
ENV HTTP_DOCUMENTROOT ${GLUSTER_VOL_PATH}/${HTTP_SITE_NAME}/documentroot

EXPOSE ${HTTP_CLIENT_PORT}
EXPOSE ${GAME_SERVER_PORT}

RUN mkdir -p /var/log/supervisor ${GLUSTER_VOL_PATH}
WORKDIR ${GLUSTER_VOL_PATH}

# Add Python API for rancher-metadata
RUN pip install rancher_metadata

# Add logrotate setting
ADD assets/setup/logrotate-supervisor.conf /etc/logrotate.d/supervisord

# Add supervisor setting
ADD assets/setup/supervisor-cron.conf /etc/supervisor/conf.d/cron.conf

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./etc/nginx/sites-available/site /etc/nginx/sites-available/${HTTP_SITE_NAME}

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm -f /etc/nginx/sites-enabled/default

RUN perl -p -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini

# Enable to run PHP in html files
RUN perl -p -i -e "s/;security.limit_extensions = .php .php3 .php4 .php5/security.limit_extensions = .php .html/g" /etc/php5/fpm/pool.d/www.conf

RUN perl -p -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf

RUN ln -fs /etc/nginx/sites-available/${HTTP_SITE_NAME} /etc/nginx/sites-enabled/${HTTP_SITE_NAME}
RUN perl -p -i -e "s/HTTP_CLIENT_PORT/${HTTP_CLIENT_PORT}/g" /etc/nginx/sites-enabled/${HTTP_SITE_NAME}
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/${HTTP_SITE_NAME}

RUN perl -p -i -e "s/GAME_SERVER_PORT/${GAME_SERVER_PORT}/g" /etc/supervisor/conf.d/supervisord.conf
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/supervisor/conf.d/supervisord.conf

# CLEAN APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/usr/local/bin/run.sh"]

FROM bmaltais/rancher-stack-base-14-04:latest

# Inspiration for php5 integration from from https://github.com/ftx/rancher-nginx-php-gluster-ha

RUN add-apt-repository -y ppa:gluster/glusterfs-3.8 && \
    apt-get update && \
    apt-get install -y nginx glusterfs-client dnsutils iputils-ping php5-fpm

ENV GLUSTER_VOL ranchervol
ENV GLUSTER_VOL_PATH /mnt/${GLUSTER_VOL}
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

RUN perl -p -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN perl -p -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf

RUN ln -fs /etc/nginx/sites-available/asteroids /etc/nginx/sites-enabled/asteroids
RUN perl -p -i -e "s/HTTP_CLIENT_PORT/${HTTP_CLIENT_PORT}/g" /etc/nginx/sites-enabled/asteroids
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/asteroids

RUN perl -p -i -e "s/GAME_SERVER_PORT/${GAME_SERVER_PORT}/g" /etc/supervisor/conf.d/supervisord.conf
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/local/bin/run.sh"]

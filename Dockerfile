FROM bmaltais/rancher-stack-base:latest

# MAINTAINER Manel Martinez <manel@nixelsolutions.com>

RUN apt-get update && \
    apt-get install -y nginx php glusterfs-client dnsutils iputils-ping
RUN add-apt-repository -y ppa:ondrej/php5
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl\
		       php5-gd php5-mcrypt php5-intl php5-imap php5-tidy sed

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
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

RUN ln -fs /etc/nginx/sites-available/asteroids /etc/nginx/sites-enabled/asteroids
RUN perl -p -i -e "s/HTTP_CLIENT_PORT/${HTTP_CLIENT_PORT}/g" /etc/nginx/sites-enabled/asteroids
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/nginx/sites-enabled/asteroids

RUN perl -p -i -e "s/GAME_SERVER_PORT/${GAME_SERVER_PORT}/g" /etc/supervisor/conf.d/supervisord.conf
RUN HTTP_ESCAPED_DOCROOT=`echo ${HTTP_DOCUMENTROOT} | sed "s/\//\\\\\\\\\//g"` && perl -p -i -e "s/HTTP_DOCUMENTROOT/${HTTP_ESCAPED_DOCROOT}/g" /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/local/bin/run.sh"]

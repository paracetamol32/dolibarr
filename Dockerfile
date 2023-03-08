FROM alpine:3.13

LABEL maintainer="docker@upshift.fr"

RUN set -eux; \
	# install needed packages
	# see https://wiki.dolibarr.org/index.php/Dependencies_and_external_libraries
	apk add --no-cache \
		bash \
		openssl \
		rsync \
		apache2 \
		php8-apache2 \
		php8-session \
		php8-mysqli \
		php8-pgsql \
		php8-ldap \
		php8-mcrypt \
		php8-openssl \
		php8-mbstring \
		php8-intl \
		php8-gd \
		php8-imagick \
		php8-soap \
		php8-curl \
		php8-calendar \
		php8-json \
		php8-xml \
		php8-xmlreader \
		php8-xmlwriter \
		php8-zip \
		php8-tokenizer \
		php8-simplexml \
		php8-opcache \
		php8 \
		mariadb-client \
		postgresql-client \
		unzip \
		tzdata \
	; \
	install -d -o apache -g root -m 0750 /var/www/html; \
	rm -rf /var/www/localhost/htdocs; \
	ln -s /var/www/html /var/www/localhost/htdocs

ENV DOLI_VERSION 17.0.0

ENV DOLI_DB_TYPE mysqli
ENV DOLI_DB_HOST db
ENV DOLI_DB_PORT 3306
ENV DOLI_DB_USER dolibarr
ENV DOLI_DB_PASSWORD dolibarr
ENV DOLI_DB_NAME dolibarr
ENV DOLI_DB_PREFIX llx_
ENV DOLI_DB_CHARACTER_SET utf8
ENV DOLI_DB_COLLATION utf8_unicode_ci

ENV DOLI_DB_ROOT_LOGIN ''
ENV DOLI_DB_ROOT_PASSWORD ''

ENV DOLI_ADMIN_LOGIN admin
ENV DOLI_ADMIN_PASSWORD dolibarr
ENV DOLI_MODULES ''

ENV DOLI_URL_ROOT 'http://localhost'

ENV DOLI_AUTH dolibarr

ENV DOLI_LDAP_HOST 127.0.0.1
ENV DOLI_LDAP_PORT 389
ENV DOLI_LDAP_VERSION 3
ENV DOLI_LDAP_SERVERTYPE openldap
ENV DOLI_LDAP_LOGIN_ATTRIBUTE uid
ENV DOLI_LDAP_DN ''
ENV DOLI_LDAP_FILTER ''
ENV DOLI_LDAP_ADMIN_LOGIN ''
ENV DOLI_LDAP_ADMIN_PASS ''
ENV DOLI_LDAP_DEBUG false

ENV DOLI_HTTPS 0
ENV DOLI_PROD 0
ENV DOLI_NO_CSRF_CHECK 0

ENV PHP_INI_upload_max_filesize=50M
ENV PHP_INI_memory_limit=256M
ENV PHP_INI_max_execution_time=60

ENV LANG fr_FR

VOLUME /var/www/html
VOLUME /var/www/documents

# Get Dolibarr
ADD https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.zip /tmp/dolibarr.zip
#COPY /dolibarr-${DOLI_VERSION}.zip /tmp/dolibarr.zip
RUN set -eux; \
	unzip -q /tmp/dolibarr.zip -d /tmp/dolibarr; \
	rm -f /tmp/dolibarr.zip; \
	mkdir -p /usr/src/dolibarr; \
	cp -r /tmp/dolibarr/dolibarr-${DOLI_VERSION}/* /usr/src/dolibarr; \
	rm -rf /tmp/dolibarr; \
	chmod +x /usr/src/dolibarr/scripts/*

WORKDIR /var/www/html

EXPOSE 80/tcp

COPY /src/docker-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-entrypoint"]

COPY /src/apache2-foreground /usr/local/bin/
CMD ["apache2-foreground"]

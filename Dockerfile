# PHP 8.3.36 : correctif PHP2Shell (CVE-2026-109618 / CVE-2026-109619).
# Variante bookworm : l'extension imap a besoin de libc-client (uw-imap), absent de Debian trixie.
FROM php:8.3.36-apache-bookworm@sha256:28e0194d65d1c25ae279366137a027e2d8a835f1b37d8b96724a32c401ef99eb

LABEL maintainer="dm@vecteur.it"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        openssl \
        rsync \
        mariadb-client \
        postgresql-client \
        unzip \
        tzdata \
    ; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends \
        libc-client-dev \
        libkrb5-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libicu-dev \
        libldap2-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-configure ldap --with-libdir="lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-install -j "$(nproc)" \
        calendar \
        gd \
        imap \
        intl \
        ldap \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        zip \
    ; \
# Ne garder que les bibliothèques d'exécution des extensions compilées
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    extDir="$(php -r 'echo ini_get("extension_dir");')"; \
    ldd "$extDir"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    ! { ldd "$extDir"/*.so | grep 'not found'; }; \
    \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    sed -i \
        -e 's%^;*allow_url_fopen\s*=.*%allow_url_fopen = On%' \
        -e 's%^;*disable_functions\s*=.*%disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,passthru,shell_exec,system,proc_open,popen%' \
        -e 's%^;*max_execution_time\s*=.*%max_execution_time = 60%' \
        -e 's%^;*memory_limit\s*=.*%memory_limit = 256M%' \
        -e 's%^;*open_basedir\s*=.*%open_basedir = /var/www/html:/var/www/documents:/var/www/run:/tmp%' \
        -e 's%^;*post_max_size\s*=.*%post_max_size = 50M%' \
        -e 's%^;*session\.cookie_samesite\s*=.*%session.cookie_samesite = Lax%' \
        -e 's%^;*session\.save_path\s*=.*%session.save_path = /var/www/run%' \
        -e 's%^;*session\.use_strict_mode\s*=.*%session.use_strict_mode = 1%' \
        -e 's%^;*session\.upload_progress\.enabled\s*=.*%session.upload_progress.enabled = Off%' \
        -e 's%^;*upload_max_filesize\s*=.*%upload_max_filesize = 50M%' \
        "$PHP_INI_DIR/php.ini" \
    ; \
    a2enmod deflate; \
    a2dismod -f autoindex; \
    echo \
        'AddOutputFilterByType DEFLATE text/html text/plain text/json text/xml text/css text/javascript application/javascript' \
        > /etc/apache2/conf-available/dolibarr-deflate.conf \
    ; \
    a2enconf dolibarr-deflate; \
# Sessions PHP (sous Alpine, /var/www/run était un lien vers /run/apache2)
    install -d -o www-data -g root -m 0770 /var/www/run; \
    install -d -o www-data -g root -m 0750 /var/www/html

ENV DOLI_VERSION 24.0.1

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
ENV DOLI_DB_TEST ''
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

ENV LANG fr_FR

VOLUME /var/www/html
VOLUME /var/www/documents

RUN set -eux; \
    curl -fsSL https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.zip -o /tmp/dolibarr.zip; \
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

# apache2-foreground fourni par l'image php officielle (lance apache2, pas httpd)
CMD ["apache2-foreground"]

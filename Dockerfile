FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql mysqli

# Configure Apache to log to stdout/stderr for Promtail collection
RUN sed -i 's|ErrorLog /var/log/apache2/error.log|ErrorLog /proc/self/fd/2|' /etc/apache2/apache2.conf && \
    sed -i 's|CustomLog /var/log/apache2/access.log combined|CustomLog /proc/self/fd/1 combined|' /etc/apache2/conf-available/other-vhosts-access-log.conf

COPY ./app /var/www/html

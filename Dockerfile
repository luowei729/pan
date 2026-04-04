FROM php:8.2-apache

# Set timezone to Beijing (Asia/Shanghai)
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN docker-php-ext-install pdo pdo_mysql mysqli

# Configure PHP upload limits for large file uploads
RUN echo "upload_max_filesize = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini

# Configure Apache to log to stdout/stderr for Promtail collection
RUN sed -i 's|ErrorLog /var/log/apache2/error.log|ErrorLog /proc/self/fd/2|' /etc/apache2/apache2.conf && \
    sed -i 's|CustomLog /var/log/apache2/access.log combined|CustomLog /proc/self/fd/1 combined|' /etc/apache2/conf-available/other-vhosts-access-log.conf

COPY ./app /var/www/html

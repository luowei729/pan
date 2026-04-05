FROM php:8.2-fpm

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN docker-php-ext-install pdo pdo_mysql mysqli

RUN echo "upload_max_filesize = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini

RUN mkdir -p /var/run/php && \
    chown -R www-data:www-data /var/www/html

COPY --from=nginx:alpine /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=nginx:alpine /etc/nginx/conf.d /etc/nginx/conf.d

COPY ./app /var/www/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["php-fpm"]
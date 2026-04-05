FROM php:8.2-fpm

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN docker-php-ext-install pdo pdo_mysql mysqli

RUN echo "upload_max_filesize = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 50G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 600" >> /usr/local/etc/php/conf.d/uploads.ini

# 安装 nginx 和 supervisor
RUN apt-get update && apt-get install -y nginx supervisor && rm -rf /var/lib/apt/lists/*

# 确保目录存在并设置权限
RUN mkdir -p /var/run/php /var/www/html && \
    chown -R www-data:www-data /var/www/html

# 复制应用代码
COPY ./app /var/www/html

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 配置 supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

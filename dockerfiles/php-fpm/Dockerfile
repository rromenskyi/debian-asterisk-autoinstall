FROM jkaninda/nginx-php-fpm:8.3
# Copy project files
COPY . /var/www/html
# Storage Volume
VOLUME /var/www/html/storage

WORKDIR /var/www/html

# Custom cache invalidation / optional
#ARG CACHEBUST=1
# composer install / Optional
#RUN composer install
# Fix permissions
RUN chown -R www-data:www-data /var/www/html

USER www-data

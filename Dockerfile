#before staring docker change disk to goinfre!!
#docker build -t ft_server . 					//build the image
#docker run -d --name=ft_server_container ft_server //building the container
#docker run -it -p 80:80 f0b60f78a423
#docker container stop wormonastring			//stops the container, do this before prune
#docker system prune 							//clear unused containers
#docker ps 										//shows running containers
#docker container ls -a 						//shows list of all containers
#docker system prune -a
#docker rmi 									//remove image
#https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# openssl req \											//to get the certificate crt
#       -newkey rsa:2048 -nodes -keyout domain.key \
 #      -x509 -days 365 -subj '/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=localhost' -out domain.crt

#Install base image for debian buster, the  OS
FROM debian:buster
#MAINTAINER Ange
RUN apt-get update -y && \
	apt-get install -y \
	mariadb-server \
	mariadb-client \
	php-fpm \
	php-mysql \
	php7.3 \
	php7.3-fpm \
	php7.3-mysql \
	php-common \
	php7.3-cli \
	php7.3-common \
	php7.3-json \
	php7.3-opcache \
	php7.3-readline \
	php7.3-mbstring \
	nginx \
	wget \
	openssl \
	sendmail

#Generates new certiifacate
RUN openssl genrsa -out /etc/ssl/certs/domain.key 2048 && \								
    openssl req -x509 -days 356 -nodes -new -key /etc/ssl/certs/domain.key \
    -subj '/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=domain' -out /etc/ssl/certs/domain.crt
#installs phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-all-languages.tar.gz && \
	tar -zxvf phpMyAdmin-4.9.4-all-languages.tar.gz && mv phpMyAdmin-4.9.4-all-languages /var/www/html/phpmyadmin

#RUN wget https://wordpress.org/wordpress-5.4.tar.gz && \
#	tar -zxvf wordpress-5.4.tar.gz -C /var/www/html

RUN mkdir /var/www/html/phpmyadmin/tmp && chmod +w /var/www/html/phpmyadmin/tmp
COPY ./srcs/config.inc.php /var/www/html/phpmyadmin

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/local/bin/wp
#moevs ugly tar
#COPY	/srcs/phpMyAdmin-4.9+snapshot-all-languages.tar.gz /tmp/
#moves certficate
#COPY ./srcs/domain.crt /etc/ssl/certs/
#COPY ./srcs/domain.key /etc/ssl/certs/
#configures nginx and runs it
COPY ./srcs/nginx.conf /etc/nginx/sites-available/localhost
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/localhost && nginx -t

RUN service mysql start && \
	#mysql -e "UPDATE mysql.user SET plugin = 'mysql_native_password', authentication_string = PASSWORD('securepassword') WHERE User = 'root';"  && \
	mysql -e "CREATE USER 'angeli'@'localhost' IDENTIFIED BY '$ecurepassword'; " && \
	mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'angeli'@'localhost';" && \
	mysql -e "FLUSH PRIVILEGES;" && \
	mysql < /var/www/html/phpmyadmin/sql/create_tables.sql
	#mysql -e "CREATE DATABASE wordpress_db;"

#configure wordpress
RUN mkdir /var/www/html/wordpress
RUN cd /var/www/html/wordpress && \
	service mysql start && \
	wp cli update && \
	wp core download --allow-root && \
	wp core config --allow-root --dbname=wordpress_db --dbuser=angeli --dbpass=$ecurepassword --dbhost=localhost --dbprefix=wp_ && \
	echo "define( 'WP_DEBUG', true );" >> /var/www/html/wordpress/wp-config.php && \
	echo "define( 'WP_DEBUG_LOG', true );" >> /var/www/html/wordpress/wp-config.php && \
	wp db create --allow-root && \
	wp core install --url=https://localhost/wordpress --title=dₒcₖₑᵣⓌⓗⓨ --admin_user=lemao --admin_password=lemao$ --admin_email=solange@kalea.nl --allow-root

#sets max uploaf file size
RUN        sed -i '/upload_max_filesize/c upload_max_filesize = 20M' /etc/php/7.3/fpm/php.ini
RUN        sed -i '/post_max_size/c post_max_size = 21M' /etc/php/7.3/fpm/php.ini

#Grants ownership
RUN chown -R www-data:www-data /var/www/html/*

#open ports with -p flaggy
EXPOSE 80 443 

CMD		service php7.3-fpm start && service nginx start && service mysql start && bash

# ENTRYPOINT ["/entrypoint.sh"]
#COPY ./srcs/nginx.conf /tmp/
#RUN mv /tmp/nginx.conf /etc/nginx/sites-available/default
# COPY srcs/entrypoint.sh /
# RUN chmod +x /entrypoint.sh
# nginx config file for local host
# copy nginx config file into the right place
#  link the sites available to the sites enabled with nginx
#  generate SSL certificates 

#install php myadmin and wordpress

#RUN	UPDATE mysql.user SET plugin = 'mysql_native_password', authentication_string = PASSWORD('securepassword') WHERE User = 'angeli'; FLUSH PRIVILEGES
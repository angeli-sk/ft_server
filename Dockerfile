#----------------------------------------------------#
#✧･ﾟ: *✧･ﾟ:*  *:･ﾟ✧*:･ﾟ✧✧･ *✧･ﾟ:*✧*:･ﾟ✧: *✧･ﾟ:*  *:･ﾟ#
#													 #
#  ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗  #
#  ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗ #
#  ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝ #
#  ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗ #
#  ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║ #
#  ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ #
#													 #
#✧･ﾟ: *✧･ﾟ:*  *:･ﾟ✧*:･ﾟ✧✧･ *✧･ﾟ:*✧*:･ﾟ✧: *✧･ﾟ:*  *:･ #
#----------------------------------------------------#

#docker build -t ft_server . 					//build the image
#docker run -it -p 80:80 -p 443:443 ft_server	//building the container
#docker container stop ft_server				//stops the container, do this before prune
#docker ps 										//shows running containers
#docker container ls -a 						//shows list of all containers
#docker system prune -a							//clear unused containers
#docker rmi 									//remove image

#https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

#To get the certificate crt;
#Openssl tool for creating and managing OpenSSL certificates, keys, and other files.
#The req command primarily creates and processes certificate requests, 
#it can additionally create self signed certificates for use as root CAs

# openssl req \											
#	-newkey rsa:2048 -nodes -keyout domain.key \			
#	-x509 -days 365 -subj '/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=localhost' -out domain.crt

#----------------------------------------------------#

#Install base image for debian buster, the  OS
#	creates a layer from the debian:buster Docker image
FROM debian:buster

#apt update kijkt of er een update is
#apt upgrade gaat dadwerkelijk de updtae uitvoeren
RUN apt-get update -y && \
	apt-get upgrade -y && \
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

#Generates new certifacate
#	SSL (Secure Sockets Layer) is a protocol for establishing authenticated and encrypted links between networked computers.
#	genrsa command generates an RSA private key with the rsa encryption
RUN openssl genrsa -out /etc/ssl/certs/domain.key 2048 && \								
    openssl req -x509 -days 356 -nodes -new -key /etc/ssl/certs/domain.key \
    -subj '/C=NL/ST=NH/L=Amsterdam/O=Codam/CN=domain' -out /etc/ssl/certs/domain.crt

#installs phpmyadmin
#	Database Management, allows a person to organize, store and retrieve data from a computer
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-all-languages.tar.gz && \
	tar -zxvf phpMyAdmin-4.9.4-all-languages.tar.gz && mv phpMyAdmin-4.9.4-all-languages /var/www/html/phpmyadmin

RUN mkdir /var/www/html/phpmyadmin/tmp && chmod +w /var/www/html/phpmyadmin/tmp
COPY ./srcs/config.inc.php /var/www/html/phpmyadmin

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/local/bin/wp

#moves certficate
#	COPY ./srcs/domain.crt /etc/ssl/certs/
#	COPY ./srcs/domain.key /etc/ssl/certs/

#configures nginx and runs it
COPY ./srcs/nginx.conf /etc/nginx/sites-available/localhost
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/localhost && nginx -t

RUN service mysql start && \
	mysql -e "CREATE USER 'angeli'@'localhost' IDENTIFIED BY '$ecurepassword'; " && \
	mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'angeli'@'localhost';" && \
	mysql -e "FLUSH PRIVILEGES;" && \
	mysql < /var/www/html/phpmyadmin/sql/create_tables.sql

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

#sets max upload file size
RUN        sed -i '/upload_max_filesize/c upload_max_filesize = 20M' /etc/php/7.3/fpm/php.ini
RUN        sed -i '/post_max_size/c post_max_size = 21M' /etc/php/7.3/fpm/php.ini

#Grants ownership
RUN chown -R www-data:www-data /var/www/html/*

#open ports with -p flaggy
EXPOSE 80 443 

#The main purpose of a CMD is to provide defaults for an executing container. 
#These defaults can include an executable, or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
CMD		service php7.3-fpm start && service nginx start && service mysql start && bash

#----------------------------------------------------#

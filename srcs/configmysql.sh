mysql
UPDATE mysql.user SET plugin = 'mysql_native_password', authentication_string = PASSWORD('securepassword') WHERE User = 'root';
FLUSH PRIVILEGES;
exit
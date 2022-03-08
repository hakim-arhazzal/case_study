# PXL Vision Case Study Analysis

This file contains a set of improvements that would benefit the case study on different levels, it's a set of my opinions, notes and suggestions, that could be implemented to furthermore improve this case study. It mainly covers  three areas (**Dockerfile**, **Wordpress with Docker-compose**, **Github Actions**)

### 1) Dockerfile

In the Dockerfile, we've implemented the following modifications to improve the file, cover the issues and get the application up and running:

#### 1.1) The first thing we need to do is change from what image we want to build the app from (Python 3.x  doesn't support all the functions in the py file), so we'll have to switch to Python 2, we've add the slim tag to reduce the size of the image thus improving the Dockerfile furthermore.

```dockerfile
FROM python:2-slim
```
#### 1.2) The Docker containers by default run with the root privilege and so does the application that runs inside the container. This is another major concern from the security perspective because hackers can gain root access to the Docker host by hacking the application running inside the container. Therefore, we've added a user 'app' to run the application as non-root.

```dockerfile
RUN addgroup --system app && adduser --system --group app 

USER app
```
#### 1.3) We created a directory to hold the application code inside the image, and help isolate our code, this will be the working directory for our application

```dockerfile
WORKDIR /usr/src/app
```
#### 1.4) We need to set an executable, that will always run when the container is initiated and can't be overridden, giving us the option to change the arguments via CMD at runtime but not the executable. 
```dockerfile
ENTRYPOINT [ "python" ]

CMD [ "./magic_ball.py" ]
```
### 2) WordPress with docker-compose

#### 2.1) Nginx Configuration

In order to add the Nginx reverse proxy,first we need to make a directory for the configuration file:

```bash
mkdir nginx-conf
nano nginx-conf/nginx.conf
```
In this file, we will add a server block with directives for our server name and document root, and location blocks.

- **listen:** This tells Nginx to listen on port 80
- **server_name**: This defines your server name and the server block that should be used for requests to your server. Be sure to replace example.com in this line with your own domain name
- **index**: The index directive defines the files that will be used as indexes when processing requests to your server. We’ve modified the default order of priority here, moving index.php in front of index.html so that Nginx prioritizes files called index.php when possible.
- **root:** Our root directive names the root directory for requests to our server. This directory, /var/www/html, is created as a mount point at build time by instructions in our WordPress Dockerfile. These Dockerfile instructions also ensure that the files from the WordPress release are mounted to this volume.

- **location /:** In this location block, we’ll use a try_files directive to check for files that match individual URI requests. Instead of returning a 404 Not Found status as a default, however, we’ll pass control to WordPress’s index.php file with the request arguments.

- **location ~ \.php$:** This location block will handle PHP processing and proxy these requests to our wordpress container. Because our WordPress Docker image will be based on the php:fpm image, we will also include configuration options that are specific to the FastCGI protocol in this block. Nginx requires an independent PHP processor for PHP requests: in our case, these requests will be handled by the php-fpm processor that’s included with the php:fpm image. Additionally, this location block includes FastCGI-specific directives, variables, and options that will proxy requests to the WordPress application running in our wordpress container, set the preferred index for the parsed request URI, and parse URI requests.
- **location ~ /\.ht:** This block will handle .htaccess files since Nginx won’t serve them. The deny_all directive ensures that .htaccess files will never be served to users.
- **location = /favicon.ico**, **location = /robots.txt**: These blocks ensure that requests to /favicon.ico and /robots.txt will not be logged.
- ***location ~* \.(css|gif|ico|jpeg|jpg|js|png)**: This block turns off logging for static asset requests and ensures that these assets are highly cacheable, as they are typically expensive to serve.

#### 2.2) Environment Variables



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

We can set the sensitive values in an **.env** file and restrict its circulation. This will prevent these values from copying over to our project repositories and being exposed publicly.

In the main project directory, ~/wordpress, we' ll open a file called .env

The confidential values that we will set in this file include a password for our MySQL root user, and a username and password that WordPress will use to access the database.

```bash
MYSQL_ROOT_PASSWORD=somewordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress
```
Giving the fact that our .env file contains sensitive information, you will want to ensure that it is included in your project’s .gitignore and .dockerignore files, which tell Git and Docker what files not to copy to your Git repositories and Docker images, respectively.

#### 2.3) Configure the Nginx revered proxy with Docker Compose

In the docker-compose file, we've introduced some changes to the **db** and **wordpress** services 

- **container_name:** This specifies a name for the container.
- **restart:** We have set the container to restart unless it is stopped manually. for troubleshooting reasons.
- **env_file:** This option tells Compose that we would like to add environment variables from a file called .env, located in our build context. In this case, the build context is our current directory.

For the wordpress service, we are using the **5.1.1-fpm-alpine WordPress** image. Using this image ensures that our application will have the php-fpm processor that Nginx requires to handle PHP processing. 

For the **Nginx webserver** service, we've introduced the following configurations

- **ports:** This exposes port 80 to enable the configuration options we defined in our nginx.conf file.
- **volumes:** Here, we are defining a combination of named volumes and bind mounts:
  - wordpress:/var/www/html: This will mount our WordPress application code to the /var/www/html directory, the directory we set as the root in our Nginx server block.

  - ./nginx-conf:/etc/nginx/conf.d: This will bind mount the Nginx configuration directory on the host to the relevant directory on the container, ensuring that any changes we make to files on the host will be reflected in the container.

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
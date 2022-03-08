# Python 3.x  doesn't support all the function in the py file
FROM python:2-slim

RUN addgroup --system app && adduser --system --group app 

USER app

# Create app directory 
WORKDIR /usr/src/app

COPY magic_ball.py .

ENTRYPOINT [ "python" ]

CMD [ "./magic_ball.py" ]

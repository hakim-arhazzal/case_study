FROM python:3

COPY magic_ball.py /

RUN pip install flask

CMD [ "python", "./magic_ball.py" ]

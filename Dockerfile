FROM python:2

RUN mkdir /workdir
ADD . /workdir
WORKDIR /workdir

RUN pip install -r requirements.txt
RUN 

FROM python:2

RUN mkdir /workdir
ADD . /workdir
WORKDIR /workdir

RUN pip install -r requirements.txt
RUN make clean html
WORKDIR /workdir/build/html

EXPOSE 8000

ADD entrypoint.sh entrypoint.sh
ENTRYPOINT ["/workdir/build/html/entrypoint.sh"]

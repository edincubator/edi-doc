FROM nginx

RUN apt-get update && apt-get install -y python3 python3-pip

RUN mkdir /workdir
ADD /doc /workdir
WORKDIR /workdir

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN make clean html
RUN cp -r /workdir/build/html/* /usr/share/nginx/html

# ADD nginx.conf /etc/nginx/nginx.conf

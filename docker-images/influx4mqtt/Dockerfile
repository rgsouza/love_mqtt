FROM node

COPY . /app

WORKDIR /app

RUN npm install -g influx4mqtt

ENTRYPOINT [ "influx4mqtt" ]
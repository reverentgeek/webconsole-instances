FROM joyent/webconsole-node:0.0.1

RUN apk update \
    && apk add --update build-base python

# Setup the Node.js app
COPY ./server.js /opt/app/server.js
COPY ./package.json /opt/app/package.json
WORKDIR /opt/app/
RUN yarn

# Setup the prestart script
COPY ./bin/prestart.sh /bin/prestart.sh
RUN chmod 700 /bin/prestart.sh

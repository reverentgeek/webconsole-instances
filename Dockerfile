FROM continuation/nginx-node-cp:1.0.0

RUN apk update \
    && apk add --update build-base python

# Setup nginx
COPY ./etc/nginx.conf /etc/nginx/nginx.conf

# Setup the Node.js app
RUN mkdir -p /opt/app/
WORKDIR /opt/app/
COPY ./index.js /opt/app/index.js
COPY ./package.json /opt/app/package.json
RUN npm install -g yarn
RUN yarn

# Move the static files to be served by nginx
RUN mkdir -p /opt/app/public/instances/static && \
    mkdir -p /opt/app/public/images/static && \
    mkdir /opt/app/public/nav-static && \
    cp -R /opt/app/node_modules/my-joy-instances/build/instances/static /opt/app/public/instances/static && \
    (cp /opt/app/node_modules/my-joy-instances/build/favicon.ico /opt/app/public/instances || true) && \
    cp /opt/app/node_modules/my-joy-instances/build/service-worker.js /opt/app/public/instances/ && \
    cp -R /opt/app/node_modules/my-joy-images/build/static /opt/app/public/images/static && \
    (cp /opt/app/node_modules/my-joy-images/build/favicon.ico /opt/app/public/images || true) && \
    cp /opt/app/node_modules/my-joy-images/build/service-worker.js /opt/app/public/images/ && \
    cp /opt/app/node_modules/my-joy-navigation/build/static/js/main.*.js /opt/app/public/nav-static/main.js && \
    cp /opt/app/node_modules/my-joy-navigation/build/static/js/main.*.js.map /opt/app/public/nav-static/main.js.map

# Setup the prestart script
COPY ./bin/prestart.sh /bin/prestart.sh
RUN chmod 700 /bin/prestart.sh

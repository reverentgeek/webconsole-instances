FROM continuation/nginx-node-cp:1.0.0

# Setup nginx
COPY ./etc/nginx.conf /etc/nginx/nginx.conf

# Setup the Node.js app
RUN mkdir -p /opt/app/
WORKDIR /opt/app/
COPY ./index.js /opt/app/index.js
COPY ./package.json /opt/app/package.json
RUN npm install -g yarn
RUN yarn

# Setup the prestart script
COPY ./bin/prestart.sh /bin/prestart.sh
RUN chmod 700 /bin/prestart.sh

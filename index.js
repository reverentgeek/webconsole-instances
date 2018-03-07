'use strict';

const Brule = require('brule');
const Hapi = require('hapi');
const Rollover = require('rollover');
const { homedir } = require('os');
const { join } = require('path');

process.env.SDC_KEY_PATH =
  process.env.SDC_KEY_PATH || join(homedir(), '.ssh/id_rsa');

const Sso = require('hapi-triton-auth');
const Ui = require('my-joy-instances');
const Nav = require('my-joy-navigation');
const Api = require('cloudapi-gql');

const {
  PORT = 3069,
  COOKIE_PASSWORD,
  COOKIE_DOMAIN,
  COOKIE_SECURE,
  COOKIE_HTTP_ONLY,
  SDC_KEY_PATH,
  SDC_ACCOUNT,
  SDC_KEY_ID,
  SDC_URL,
  BASE_URL = `http://0.0.0.0:${PORT}`,
  ROLLBAR_SERVER_TOKEN,
  NODE_ENV = 'development'
} = process.env;

const server = Hapi.server({
  port: PORT,
  host: '127.0.0.1',
  debug: { request: ['error'] }
});

process.on('unhandledRejection', (err) => {
  server.log(['error'], err);
  console.error(err);
});

async function main () {
  await server.register([
    {
      plugin: Rollover,
      options: {
        rollbar: {
          accessToken: ROLLBAR_SERVER_TOKEN,
          reportLevel: 'error'
        }
      }
    },
    {
      plugin: Brule,
      options: {
        auth: false
      }
    },
    {
      plugin: Sso,
      options: {
        ssoUrl: 'https://sso.joyent.com/login',
        baseUrl: BASE_URL,
        apiBaseUrl: SDC_URL,
        keyId: '/' + SDC_ACCOUNT + '/keys/' + SDC_KEY_ID,
        keyPath: SDC_KEY_PATH,
        permissions: { cloudapi: ['/my/*'] },
        isDev: NODE_ENV === 'development',
        cookie: {
          isHttpOnly: COOKIE_HTTP_ONLY !== '0',
          isSecure: COOKIE_SECURE !== '0',
          password: COOKIE_PASSWORD,
          ttl: 1000 * 60 * 60, // 1 hour
          domain: COOKIE_DOMAIN
        }
      }
    },
    {
      plugin: Nav
    },
    {
      plugin: Ui
    },
    {
      plugin: Api,
      options: {
        keyId: '/' + SDC_ACCOUNT + '/keys/' + SDC_KEY_ID,
        keyPath: SDC_KEY_PATH,
        apiBaseUrl: SDC_URL
      }
    }
  ]);

  server.auth.default('sso');

  await server.start();
  console.log(`server started at http://localhost:${server.info.port}`);
}

main();

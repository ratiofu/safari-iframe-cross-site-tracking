import Fastify from 'fastify';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import accepts from 'accepts';
import staticPlugin from '@fastify/static';
import cookie from '@fastify/cookie'

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PUBLIC_DIR = join(__dirname, 'public');

const fastify = Fastify({
  logger: true
});

// const { log } = fastify;

fastify.register(staticPlugin, {
  root: PUBLIC_DIR,
  prefix: '/public/',
});

fastify.register(cookie, {
  hook: 'onRequest'
  // secret: "my-secret", // for cookies signature
  // parseOptions: {}     // options for parsing cookies
})

function onApiHost(body) {
  return async (request, reply) => {
    if (request.headers.host === 'api.embedded-app.io') {
      const accept = accepts(request);
      const acceptHtml = accept.types(['json']);
      if (acceptHtml === 'json') {
        return await body(request, reply);
      }
    }
    reply.code(404).send({ error: 'Not found' });
  }
}

fastify.addHook('onRequest', async (request, reply) => {
  const host = request.headers.host;
  const accept = accepts(request);
  const acceptHtml = accept.types(['html']);

  if (acceptHtml === 'html') {
    switch (host) {
      case 'test.parent-app.io':
        return reply.sendFile('parent.html', PUBLIC_DIR);
      case 'app.embedded-app.io':
        // set the Access-Control-Allow-Origin header to allow app.embedded-app.io
        // to make requests to api.embedded-app.io
        reply.header('Access-Control-Allow-Origin', 'https://app.embedded-app.io');
        switch (request.url) {
          case '/signin':
            return reply.sendFile('popup.html', PUBLIC_DIR);
          default:
            return reply.sendFile('embedded.html', PUBLIC_DIR);
        }
    }
  }
});

fastify.addHook('onSend', function handleCors(request, reply, body, next) {
  const host = request.headers.host;
  if (host === 'api.embedded-app.io') {
    reply
      .header('Access-Control-Allow-Origin', 'https://app.embedded-app.io')
      .header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      .header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Cookie, Set-Cookie')
      .header('Access-Control-Allow-Credentials', 'true');
  }
  next(null, body);
});

fastify.post('/api/v1/authorize', await onApiHost(async (request, reply) => {
  setSecureHttpOnlyCookie(reply);
  reply.send({ authorized: true });
}));

fastify.get('/api/v1/userinfo', await onApiHost(async (request, reply) => {
  if (hasAuthorizationCookie(request)) {
    reply.send({ name: 'Carly Livingston' });
  } else {
    reply.code(401).send({ error: 'Unauthorized' });
  }
}));

const COOKIE_NAME = 'embeddedappsession';

function setSecureHttpOnlyCookie(reply) {
  reply.setCookie(COOKIE_NAME, Date.now().toString(31), {
    domain: 'embedded-app.io',
    path: '/',
    secure: true,
    httpOnly: true,
    sameSite: 'lax',
    expires: new Date(Date.now() + 1000 * 60 * 60 * 24 * 365),
  })
}

function hasAuthorizationCookie(request) {
  return !!request.cookies[COOKIE_NAME];
}

(async () => {
  try {
    await fastify.listen({ port: 8000 })
  } catch (error) {
    fastify.log.error(error)
    process.exit(1)
  }
})().catch(console.error);

// needed? --experimental-modules

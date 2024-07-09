# Dockerfile
FROM nginx:alpine
COPY nginx/*.conf /etc/nginx/
COPY ./certs /etc/nginx/certs
RUN chown root:nginx /etc/nginx/certs/*.key && chmod 640 /etc/nginx/certs/*.key

FROM nginx:latest

RUN rm /etc/nginx/conf.d/default.conf

# to make this folder available when pushed to docker hub
COPY ./Docker/prod/nginx/servers.conf /etc/nginx/conf.d/

RUN mkdir /etc/ssl/nginx

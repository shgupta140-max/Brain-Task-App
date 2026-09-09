FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN rm -rf *.html
COPY ./dist .
COPY ./nginx.conf /etc/nginx/conf.d/nginx.conf
EXPOSE 3000

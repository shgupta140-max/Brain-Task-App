FROM httpd:alpine

# Change the Apache configuration to listen on port 3001 instead of 80
RUN sed -i 's/Listen 80/Listen 3001/' /usr/local/apache2/conf/httpd.conf

# Copy your website files to the Apache web root
COPY ./html/ /usr/local/apache2/htdocs/

# Expose port 3001 to the Docker network
EXPOSE 3001

#!/bin/bash

# Generate self-signed SSL certificates for SecuriWatch
# For production use, replace with proper certificates from a CA

# Create directory if it doesn't exist
mkdir -p config/nginx/ssl

# Generate private key
openssl genrsa -out config/nginx/ssl/securiwatch.key 2048

# Generate CSR
openssl req -new -key config/nginx/ssl/securiwatch.key -out config/nginx/ssl/securiwatch.csr -subj "/C=US/ST=State/L=City/O=SecuriWatch/CN=localhost"

# Generate self-signed certificate (valid for 365 days)
openssl x509 -req -days 365 -in config/nginx/ssl/securiwatch.csr -signkey config/nginx/ssl/securiwatch.key -out config/nginx/ssl/securiwatch.crt

# Generate .htpasswd file for basic authentication
# Default credentials: admin/securiwatch
# Change this for production!
echo "admin:$(openssl passwd -apr1 securiwatch)" > config/nginx/.htpasswd

# Set permissions
chmod 600 config/nginx/ssl/securiwatch.key
chmod 600 config/nginx/.htpasswd

echo "SSL certificates generated successfully!"
echo "Default credentials: admin / securiwatch"
echo "IMPORTANT: Change these credentials before deploying to production!" 
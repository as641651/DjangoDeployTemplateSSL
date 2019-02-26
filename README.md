# DjangoDeployTemplate

### Details

> There are separate docker-compose scripts for development and production

> The production vesrsion serves django with gunicorn and nginx

### Usage

```bash
docker-compose -f prod-compose.yml build
docker-compose -f prod-compose.yml up
```

### Issue SSL certificates
```bash
# Run the server on port 80 and hit the following command
sudo ./issue-certificates.sh
```

### Using pre-issued SSL certificates

> If certificates are already available, copy SSL certificates to the folder **prod/nginx/ssl/keys**



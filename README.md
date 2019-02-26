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

1) Specify the www and non-www domain names under **REGISTERED_DOMAIN** field in **issue-certificates.sh**
```bash
# eg,
# Space separated list of domains to register SSL certificates for.
REGISTER_DOMAINS="mlr2d.org www.mlr2d.org"
```
2) Comment out (dont know if this is really needed) the **port 443 server** and the **https redirection** in **servers.conf**. Also specify **domain name** in the **port 80 server**

3) Run issue-certificate script
```bash
# Run the server on port 80 and hit the following command
sudo ./issue-certificates.sh
```
4) Once the certificates are issued, **specify the certificate paths in servers.conf**

### Using pre-issued SSL certificates

> If certificates are already available, copy SSL certificates to the folder **prod/nginx/ssl/keys**




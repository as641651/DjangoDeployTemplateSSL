#!/bin/bash


# Ensure this script stops executing if any errors occur along the way.
set -e


# -----------------------------------------------------------------------------
# HOW TO RUN THIS SCRIPT:
# 1. Make sure this script is somewhere on your system's path
# 2. Make sure it is executable, example: chmod +x issue-certificate.sh
# 3. Run it with this command: issue-certificate.sh
#
#
# HOW TO AUTOMATE RUNNING THIS SCRIPT EVERY MONTH WITH A CRON JOB:
# 1. Login as root, example: sudo su
# 2. Run this command: crontab -e
# 3. Place the line below in your editor when you are prompted to do so:
# 0 0 1 * * /usr/local/bin/issue-certificate.sh
#
# The above assumes you've placed the script into /usr/local/bin.
# -----------------------------------------------------------------------------


# Do you want to run Let's Encrypt in "staging" or "live" mode? You should only
# change this to "live" once you are sure everything is working correctly.
LETS_ENCRYPT_MODE="live"


# Space separated list of domains to register SSL certificates for.
REGISTER_DOMAINS="mlr2d.com"
# Here's an example if you had multiple domains (you could use 1 line too):
#   REGISTER_DOMAINS="example.com
#                     www.example.com
#                     blog.example.com
#                     anotherexample.com"


# Which service should we restart after issuing the certificate?
RESTART_SERVICE="nginx"


# -----------------------------------------------------------------------------
# You do not need to edit anything beyond this point. Of course you can if you
# want, but you should only do so if you know what you're doing!
# -----------------------------------------------------------------------------


# Public URL endpoints for Let's Encrypt's staging and live servers, along with
# its current cross signed certificate.
#
# You shouldn't have to change these unless LE changes them in the future.
LETS_ENCRYPT_STAGING_URL="https://acme-staging.api.letsencrypt.org"
LETS_ENCRYPT_LIVE_URL="https://acme-v01.api.letsencrypt.org"
LETS_ENCRYPT_CROSS_SIGNED_URL="https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"


# The final certificate's file name will get generated using the first domain
# defined in REGISTER_DOMAINS.
#
# For example, if you used the multiple domains example that's commented out
# on line 33, this would be set to "example.com".
CERTIFICATE_BASE_FILENAME="$(echo -e "${REGISTER_DOMAINS%% *}" \
                             | tr -d '[:space:]')"


# Default locations for where certificates will live.
ACME_TINY_SHARE_PATH="Docker/prod/nginx/ssl/acme-tiny"
ACME_TINY_LOG_PATH="Docker/prod/nginx/ssl/log/acme-tiny"
ACME_CHALLENGE_PATH="${ACME_TINY_LOG_PATH}"

PRIV_KEY_ACCOUNT="${ACME_TINY_SHARE_PATH}/account.key"
PRIV_KEY_DOMAIN="${ACME_TINY_SHARE_PATH}/${CERTIFICATE_BASE_FILENAME}.key"
DOMAIN_CSR="${ACME_TINY_SHARE_PATH}/${CERTIFICATE_BASE_FILENAME}.csr"

SIGNED_CERTIFICATE="${ACME_TINY_SHARE_PATH}/${CERTIFICATE_BASE_FILENAME}.crt"
INTERMEDIATE_CERTIFICATE="${ACME_TINY_SHARE_PATH}/intermediate.crt"

KEY_DIR="Docker/prod/nginx/ssl/key/"
FINAL_PRIV_KEY="${KEY_DIR}/${CERTIFICATE_BASE_FILENAME}.key"
CHAINED_FINAL_CERTIFICATE="${KEY_DIR}/${CERTIFICATE_BASE_FILENAME}.pem"


# Create the acme-tiny install path if it doesn't exist already.
# This is where all of the key pairs and certificates will get generated into.
mkdir -p "${ACME_TINY_SHARE_PATH}"


# Create a path to store acme-tiny's log output.
mkdir -p "${ACME_TINY_LOG_PATH}"

# path to store keys for mapping to container
mkdir -p "${KEY_DIR}"


# Create the account and domain keys, but only when they don't exist.
# These only need to be generated once (yep, even if the domain changes).
if [ ! -f "${PRIV_KEY_ACCOUNT}" ]; then
    openssl genrsa -out "${PRIV_KEY_ACCOUNT}"
fi

if [ ! -f "${PRIV_KEY_DOMAIN}" ]; then
    openssl genrsa -out "${PRIV_KEY_DOMAIN}"
fi


# Create the domain CSR (certificate signing request).
for domain in ${REGISTER_DOMAINS}
do
    SAN_DOMAINS_LIST+=",DNS:${domain}"
done
SAN_DOMAINS_LIST="${SAN_DOMAINS_LIST:1}"

SAN_OUTPUT="[SAN]\nsubjectAltName=${SAN_DOMAINS_LIST}"
openssl req -new -sha256 -key "${PRIV_KEY_DOMAIN}" -subj "/" -reqexts SAN \
        -config <(cat /etc/ssl/openssl.cnf <(printf "${SAN_OUTPUT}")) \
        -out "${DOMAIN_CSR}"



# Default to the staging server unless "live" is explicitly set.
LETS_ENCRYPT_CA_URL="${LETS_ENCRYPT_STAGING_URL}"
if [ "${LETS_ENCRYPT_MODE}" == "live" ]; then
    LETS_ENCRYPT_CA_URL="${LETS_ENCRYPT_LIVE_URL}"
fi

# Generate a Let's Encrypt SSL certificate.
# 2>> redirects STDOUT and STDERR to STDOUT and appends it to the log file.
python acme-tiny.py \
    --account-key "${PRIV_KEY_ACCOUNT}" \
    --csr "${DOMAIN_CSR}" \
    --acme-dir "${ACME_CHALLENGE_PATH}" \
    --ca "${LETS_ENCRYPT_CA_URL}" > "${SIGNED_CERTIFICATE}" \
    2>> "${ACME_TINY_LOG_PATH}/acme-tiny.log"


# Complete the trust chain by pulling down a fresh cross signed certificate.
# This is necessary to get an A+ rated SSL certificate.
#
# This gets written to its final destination so that nginx can read it.
wget "${LETS_ENCRYPT_CROSS_SIGNED_URL}" -O "${INTERMEDIATE_CERTIFICATE}"
cat "${SIGNED_CERTIFICATE}" "${INTERMEDIATE_CERTIFICATE}" \
    > "${CHAINED_FINAL_CERTIFICATE}"


# Copy the private domain.key over to where nginx can read it.
cp "${PRIV_KEY_DOMAIN}" "${FINAL_PRIV_KEY}"


# Restart nginx / apache2 / haproxy / etc. to pickup the certificate change.
#service "${RESTART_SERVICE}" restart

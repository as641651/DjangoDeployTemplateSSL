FROM python:3.7-alpine
MAINTAINER senesence

COPY ./requirements/prod.txt /requirements.txt

RUN pip install -r /requirements.txt

RUN mkdir /app
WORKDIR /app

# to make this folder available when pushed to docker hub
COPY ./app /app

# Create a user. -D represents this user can only run apps.
RUN adduser -D user

# -p allows creation of sub-directories if not available
RUN mkdir -p /vol/static
# Give permission to user to access volume dirs
RUN chown -R user:user /vol/
# This means owner can do everything, but rest can only read and execute
RUN chmod -R 755 /vol/

USER user

#!/bin/bash

NAME="GRVTY"                                      # Name of the application
DJANGODIR=/webapps/GRVTY/GRVTY                    # Django project directory
SOCKFILE=/webapps/GRVTY/run/gunicorn.sock         # we will communicte using this unix socket
USER=grvtyuser                                    # the user to run as
GROUP=webapps                                     # the group to run as
NUM_WORKERS=3                                     # how many worker processes should Gunicorn spawn
DJANGO_SETTINGS_MODULE=GRVTY.settings             # which settings file should Django use
DJANGO_WSGI_MODULE=GRVTY.wsgi                     # WSGI module name

export DJANGO_PROJECT_NAME=GRVTY
export DJANGO_ENV=production
export DJANGO_LOCAL_DB=false
export DJANGO_PWD_DB='NOPE_CHUCK_TESTA'
export DJANGO_SECRET_KEY='NOPE_CHUCK_TESTA'

export DJANGO_ALLOWED_HOSTS=127.0.0.1,localhost
export DJANGO_ADMINS="(('NOPE_CHUCK_TESTA', 'nope_chuck_testa@grvtylabs.com'),)"

export DJANGO_GMAIL_USER=nope_chuck_testa@gmail.com
export DJANGO_GMAIL_PWD=nope_chuck_testa
export WAGTAILEMBEDS_EMBEDLY_KEY=nope_chuck_testa

echo "Starting $NAME as `whoami`"

# Activate the virtual environment
cd $DJANGODIR
source /webapps/GRVTY/bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

# Create the run directory if it doesn't exist
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec /webapps/GRVTY/bin/gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $NUM_WORKERS \
  --user=$USER --group=$GROUP \
  --bind=unix:$SOCKFILE \
  --log-level=debug \
  --log-file=-

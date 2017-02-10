base_dir_name=Supplayers
project_name=Supplayers
user_name=supplayers_user
group_name=supplayers_group
giturl=git@github.com:grvty-labs/"$project_name".git
server_runner=daphne

install_os_deps=false

function add_git_config {
  sudo cat << EOF > ~/.ssh/config
host github.com
 HostName github.com
 IdentityFile ~/.ssh/deploy_github
 User git
EOF
}

function install_allos_deps {
  if [ "$install_os_deps" = true ]; then
    sudo apt-get install -y supervisor nginx git postgresql postgresql-contrib postgresql-server-dev-9.5 redis-server

    sudo apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk \
        python-imaging python3
    sudo ln -s /usr/include/freetype2 /usr/local/include/freetype

    sudo apt-get install libxml2 libxslt1.1 libxml2-dev libxslt1-dev

    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    sudo apt-get install -y nodejs

    sudo apt-get install python3-pip
    pip3 install virtualenv
  fi
}

function create_project_gunicorn {
  if [ "$server_runner" = "gunicorn" ]; then
    # CREATE GUNICORN START FILE
    cat << EOF > /webapps/"$base_dir_name"/bin/gunicorn_start.bash
#!/bin/bash

NAME="$base_dir_name-Gunicorn"                    # Name of the application
DJANGODIR=/webapps/$base_dir_name/$project_name   # Django project directory
SOCKFILE=/webapps/$base_dir_name/run/gunicorn.sock # we will communicte using this unix socket
USER=$user_name                                   # the user to run as
GROUP=$group_name                                 # the group to run as
NUM_WORKERS=3                                     # how many worker processes should Gunicorn spawn
DJANGO_SETTINGS_MODULE=$project_name.settings     # which settings file should Django use
DJANGO_WSGI_MODULE=$project_name.wsgi             # WSGI module name

echo "Starting \$NAME as `whoami`"

# Activate the virtual environment
cd \$DJANGODIR
source /webapps/$base_dir_name/bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

# Create the run directory if it doesn't exist
RUNDIR=\$(dirname \$SOCKFILE)
test -d \$RUNDIR || mkdir -p \$RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec /webapps/$base_dir_name/bin/gunicorn \${DJANGO_WSGI_MODULE}:application \
  --name \$NAME \
  --workers \$NUM_WORKERS \
  --user=\$USER --group=\$GROUP \
  --bind=unix:\$SOCKFILE \
  --log-level=debug \
  --log-file=-

EOF
    sudo chmod u+x /webapps/$base_dir_name/bin/gunicorn_start.bash
    echo ">> GUNICORN.bash Configured"
  fi
}

function create_project_celery {
  # CREATE GUNICORN START FILE
  cat << EOF > /webapps/"$base_dir_name"/bin/celery_start.bash
#!/bin/bash

NAME="$base_dir_name-Celery"
DJANGODIR=/webapps/$base_dir_name/$project_name
USER=$user_name
GROUP=$group_name
DJANGO_SETTINGS_MODULE=$project_name.settings
DJANGO_WSGI_MODULE=$project_name.wsgi             # WSGI module name

echo "Starting \$NAME as `whoami`"

# Activate the virtual environment
cd \$DJANGODIR
source /webapps/$base_dir_name/bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec /webapps/$base_dir_name/bin/celery worker -A $project_name -l WARNING

EOF
  sudo chmod u+x /webapps/$base_dir_name/bin/celery_start.bash
  echo ">> CELERY.bash Configured"
}

function create_project_daphne {
  if [ "$server_runner" = "daphne" ]; then
    # CREATE DAPHNE WORKER START FILE
    cat << EOF > /webapps/$base_dir_name/bin/daphneworker_start.bash
#!/bin/bash
NAME="$base_dir_name-DaphneWorker"
DJANGODIR=/webapps/$base_dir_name/$project_name
DJANGO_SETTINGS_MODULE=$project_name.settings
DJANGO_ASGI_MODULE=$project_name.asgi
DJANGO_WSGI_MODULE=$project_name.wsgi

echo "Starting \$NAME as `whoami`"

# Activate the virtual environment
cd \$DJANGODIR
source /webapps/$base_dir_name/bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

# Start your Daphne
exec python manage.py runworker
EOF
    sudo chmod u+x /webapps/$base_dir_name/bin/daphneworker_start.bash

    # CREATE DAPHNE INTERFACE SERVER START FILE
    cat << EOF > /webapps/$base_dir_name/bin/daphne_start.bash
#!/bin/bash

NAME="$base_dir_name-Daphne"
DJANGODIR=/webapps/$base_dir_name/$project_name
# SOCKFILE=/webapps/$base_dir_name/run/daphne.sock
DJANGO_SETTINGS_MODULE=$project_name.settings
DJANGO_ASGI_MODULE=$project_name.asgi
DJANGO_WSGI_MODULE=$project_name.wsgi

# RUNDIR=\$(dirname \$SOCKFILE)
# test -d \$RUNDIR || mkdir -p \$RUNDIR
echo "Starting \$NAME as `whoami`"

# Activate the virtual environment
cd \$DJANGODIR
source /webapps/$base_dir_name/bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

# Start your Daphne
exec /webapps/$base_dir_name/bin/daphne -b 127.0.0.1 -p 8000 \${DJANGO_ASGI_MODULE}:channel_layer
 # \${DJANGO_ASGI_MODULE}:channel_layer -u \$SOCKFILE
EOF
    sudo chmod u+x /webapps/$base_dir_name/bin/daphne_start.bash
    echo ">> DAPHNE Configured"
  fi
}

function create_project {
  echo "PLEASE RUN THE FOLLOWING COMMANDS MANUALLY:"
  echo "createuser -S -R -D -P django_$project_name"
  echo "[password]"
  echo "createdb --owner django_$project_name $project_name"
  echo "logout"
  sudo su - postgres

  cd /webapps
  virtualenv -p python3 "$base_dir_name"

  sudo mkdir -p /webapps/$base_dir_name/.ssh
  sudo cp ~/.ssh/config /webapps/$base_dir_name/.ssh
  sudo cp ~/.ssh/deploy_github /webapps/$base_dir_name/.ssh

  echo -n "" >> /webapps/"$base_dir_name"/bin/activate
  echo -n "# NOTE: Add your project exports" >> /webapps/"$base_dir_name"/bin/activate
  sudo nano /webapps/"$base_dir_name"/bin/activate

  # CREATE GUNICORN LOGS AND SOCK
  cd $base_dir_name
  mkdir -p run
  mkdir -p logs

  create_project_gunicorn
  create_project_celery
  create_project_daphne

  source /webapps/$base_dir_name/bin/activate
  git clone $giturl
  cd "$project_name"
  pip3 install -r requirements.txt
  pip3 install gunicorn
  python3 manage.py collectstatic --noinput
  python3 manage.py migrate
  python3 manage.py deploydefaults
}

function create_users {
  sudo groupadd --system "$group_name"
  sudo useradd --system --gid "$group_name" --shell /bin/bash --home /webapps/"$base_dir_name" "$user_name"

  sudo chown "$user_name":"$group_name" /webapps/"$base_dir_name" -R
}

function configure_supervisor_gunicorn {
  if [ "$server_runner" = "gunicorn" ]; then
    project_name_app=$project_name'Gunicorn'
    # CREATE SUPERVISOR FILE
    sudo bash -c "cat > /etc/supervisor/conf.d/$project_name_app.conf" << EOF
[program:$project_name_app]
; Command to start app
command = /webapps/$base_dir_name/bin/gunicorn_start.bash
; User to run as
user = $user_name
; Where to write log messages
stdout_logfile = /webapps/$base_dir_name/logs/gunicorn_supervisor.log
; Save stderr in the same log
redirect_stderr = true
; (max main logfile bytes b4 rotation;default 50MB)
logfile_maxbytes=50MB
; Set UTF-8 as default encoding
environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8
autostart=true
EOF
  fi
}

function configure_supervisor_celery {
  project_name_app=$project_name'Celery'
  sudo bash -c "cat > /etc/supervisor/conf.d/$project_name_app.conf" << EOF
; Obtained and modified from:
; https://goo.gl/Ij36AK

; the name of your supervisord program
[program:$project_name_app]

; Set full path to celery program if using virtualenv
command = /webapps/$base_dir_name/bin/celery_start.bash

; The directory to your Django project
directory=/webapps/$base_dir_name/$project_name

; If supervisord is run as the root user, switch users to this UNIX user account
; before doing any processing.
user=$user_name

; Supervisor will start as many instances of this program as named by numprocs
; numprocs=2
; process_name=%(program_name)s_%(process_num)2d

; Put process stdout output in this file
stdout_logfile = /webapps/$base_dir_name/logs/celery_supervisor.log

; Put process stderr output in this file
stdout_logfile = /webapps/$base_dir_name/logs/celery_supervisor_error.log

; (max main logfile bytes b4 rotation;default 50MB)
logfile_maxbytes=50MB

; If true, this program will start automatically when supervisord is started
autostart=true

; May be one of false, unexpected, or true. If false, the process will never
; be autorestarted. If unexpected, the process will be restart when the program
; exits with an exit code that is not one of the exit codes associated with this
; process’ configuration (see exitcodes). If true, the process will be
; unconditionally restarted when it exits, without regard to its exit code.
autorestart=true

; The total number of seconds which the program needs to stay running after
; a startup to consider the start successful.
startsecs=10

; Need to wait for currently executing tasks to finish at shutdown.
; Increase this if you have very long running tasks.
stopwaitsecs = 600

; When resorting to send SIGKILL to the program to terminate it
; send SIGKILL to its whole process group instead,
; taking care of its children as well.
killasgroup=true
EOF
}

function configure_supervisor_daphneworkers {
  if [ "$server_runner" = "daphne" ]; then
    project_name_app=$project_name'DaphneWorker'
    # CREATE SUPERVISOR FILE
    sudo bash -c "cat > /etc/supervisor/conf.d/$project_name_app.conf" << EOF
[program:$project_name_app]
command = /webapps/$base_dir_name/bin/daphneworker_start.bash

; numprocs=3
; process_name=%(program_name)s_%(process_num)2d
user = $user_name
stdout_logfile = /webapps/$base_dir_name/logs/daphneworker_supervisor.log
logfile_maxbytes=50MB
autostart=true
autorestart=true
redirect_stderr=true
stopasgroup=true
killasgroup=true
EOF
  fi
}

function configure_supervisor_daphne {
  if [ "$server_runner" = "daphne" ]; then
    project_name_app=$project_name'Daphne'
    # CREATE SUPERVISOR FILE
    sudo bash -c "cat > /etc/supervisor/conf.d/$project_name_app.conf" << EOF
[program:$project_name_app]
command = /webapps/$base_dir_name/bin/daphne_start.bash

user = $user_name
stdout_logfile = /webapps/$base_dir_name/logs/daphne_supervisor.log
redirect_stderr = true
logfile_maxbytes=50MB
autostart=true
autorestart=true
stopasgroup=true
EOF
  fi
}

function configure_supervisor {
  sudo supervisord -c /etc/supervisor/supervisord.conf
  sudo supervisorctl -c /etc/supervisor/supervisord.conf

  configure_supervisor_gunicorn
  configure_supervisor_celery
  configure_supervisor_daphneworkers
  configure_supervisor_daphne

  sudo supervisorctl reread
  sudo supervisorctl update
  sudo supervisorctl reload
}

function configure_nginx_gunicorn {
  if [ "$server_runner" = "gunicorn" ]; then
    project_name_app=${project_name,,}'_app_server'
    # CREATE SUPERVISOR FILE
    sudo bash -c "cat > /etc/nginx/sites-available/$project_name.nginxconf" << EOF
upstream $project_name_app {
  # fail_timeout=0 means we always retry an upstream even if it failed
  # to return a good HTTP response (in case the Unicorn master nukes a
  # single worker for timing out).

  server unix:/webapps/$base_dir_name/run/$server_runner.sock fail_timeout=0;
}

server {
    listen 80;
    server_name ${project_name,,}.grumpytopo.com;
    client_max_body_size 4G;
    access_log /webapps/$base_dir_name/logs/nginx-access.log;
    error_log /webapps/$base_dir_name/logs/nginx-error.log;

    location /built/ {
        alias /webapps/$base_dir_name/$project_name/built/;
    }

    location /media/ {
        alias /webapps/$base_dir_name/$project_name/media/;
    }

    location / {
        # an HTTP header important enough to have its own Wikipedia entry:
        #   http://en.wikipedia.org/wiki/X-Forwarded-For
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # enable this if and only if you use HTTPS, this helps Rack
        # set the proper protocol for doing redirects:
        # proxy_set_header X-Forwarded-Proto https;

        # pass the Host: header from the client right along so redirects
        # can be set properly within the Rack application
        proxy_set_header Host \$http_host;

        # we don't want nginx trying to do something clever with
        # redirects, we set the Host: header above already.
        proxy_redirect off;

        # set "proxy_buffering off" *only* for Rainbows! when doing
        # Comet/long-poll stuff.  It's also safe to set if you're
        # using only serving fast clients with Unicorn + nginx.
        # Otherwise you _want_ nginx to buffer responses to slow
        # clients, really.
        # proxy_buffering off;

        # Try to serve static files from nginx, no point in making an
        # *application* server like Unicorn/Rainbows! serve static files.
        if (!-f \$request_filename) {
            proxy_pass http://$project_name_app;
            break;
        }
    }

    # Error pages
    error_page 500 502 503 504 /500.html;
    location = /500.html {
        root /webapps/$base_dir_name/$project_name/templates/;
    }
}

EOF
    sudo ln -s /etc/nginx/sites-available/"$project_name".nginxconf /etc/nginx/sites-enabled/"$project_name".nginxconf

    sudo service nginx restart
  fi
}

function configure_nginx_daphne {
  if [ "$server_runner" = "daphne" ]; then
    project_name_app=${project_name,,}'_app_server'
    # CREATE SUPERVISOR FILE
    sudo bash -c "cat > /etc/nginx/sites-available/$project_name.nginxconf" << EOF
# Enable upgrading of connection (and websocket proxying) depending on the
# presence of the upgrade field in the client request header
map \$http_upgrade \$connection_upgrade {
  default upgrade;
  '' close;
}

# Create an upstream alias to where we've set daphne to bind to
upstream $project_name_app {
  server 127.0.0.1:8000;
}

server {
  listen 80;
  server_name ${project_name,,}.grumpytopo.com;

  client_max_body_size 4G;
  access_log /webapps/$base_dir_name/logs/nginx-access.log;
  error_log /webapps/$base_dir_name/logs/nginx-error.log;

  location /built/ {
      alias /webapps/$base_dir_name/$project_name/built/;
  }

  location /media/ {
      alias /webapps/$base_dir_name/$project_name/media/;
  }

  location / {
    if (!-f \$request_filename) {
        proxy_pass http://$project_name_app;
        break;
    }
    # Require http version 1.1 to allow for upgrade requests
    proxy_http_version 1.1;
    # We want proxy_buffering off for proxying to websockets.
    proxy_buffering off;
    # http://en.wikipedia.org/wiki/X-Forwarded-For
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    # enable this if you use HTTPS:
    # proxy_set_header X-Forwarded-Proto https;
    # pass the Host: header from the client for the sake of redirects
    proxy_set_header Host \$http_host;
    # We've set the Host header, so we don't need Nginx to muddle
    # about with redirects
    proxy_redirect off;

    # Depending on the request value, set the Upgrade and
    # connection headers
    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection \$connection_upgrade;
  }

  # Error pages
  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root /webapps/$base_dir_name/$project_name/templates/;
  }
}

EOF
    sudo ln -s /etc/nginx/sites-available/"$project_name".nginxconf /etc/nginx/sites-enabled/"$project_name".nginxconf

    sudo service nginx restart
  fi
}

# sudo dd if=/dev/zero of=/swapfile bs=1024 count=2048k
# sudo mkswap /swapfile
# sudo swapon /swapfile
# sudo swapon -s

response=
echo -n "Are you running me as sudo? [y/N] > "
read response
case $response in
  [yY][eE][sS]|[yY])
      echo "Perfect."
      ;;
  *)
      echo "Please, run this file as sudo."
      exit 0
      ;;
esac

echo -n "Did you place your deploy_github file in ~/.ssh for git deployments? [y/N] > "
read response
case $response in
  [yY][eE][sS]|[yY])
      echo "Perfect."
      ;;
  *)
      echo "Please, place the file required and retry."
      exit 0
      ;;
esac

echo ""
echo -n "Do you want to install all of the OS dependencies? [y/N] > "
read response
case $response in
  [yY][eE][sS]|[yY])
      install_os_deps=true
      echo "We will install supervisor, nginx, postgresql, redis, nodejs, npm, Pillow, LibXML and virtualenv to your OS."
      echo ""
      ;;
  *)
      install_os_deps=false
      echo "NO, just install my project"
      echo ""
      ;;
esac

echo -n "Enter name of the base DIRECTORY [$base_dir_name] > "
read response
if [ -n "$response" ]; then
    base_dir_name=$response
fi

echo ""
echo -n "Enter name of the PROJECT (the same as your git) [$project_name] > "
read response
if [ -n "$response" ]; then
    project_name=$response
fi

echo ""
echo -n "Enter name of the system USER which will run the project [$user_name] > "
read response
if [ -n "$response" ]; then
    user_name=$response
fi

echo ""
echo -n "Enter name of the system GROUP which will run the project [$group_name] > "
read response
if [ -n "$response" ]; then
    group_name=$response
fi

echo ""
echo -n "Enter the URL of the git project [$giturl] > "
read response
if [ -n "$response" ]; then
    giturl=$response
fi

echo ""
echo -n "Do you want to configure the server using Daphne or Gunicorn? [$server_runner] > "
read response
if [ -n "$response" ]; then
  if [ "$response" == "gunicorn" ]; then
    server_runner=$response
  else
    if [ "$response" == "daphne" ]; then
      server_runner=$response
    else
      echo "ERROR: Invalid"
      exit 1
    fi
  fi
fi

add_git_config
install_allos_deps
create_project
create_users
configure_supervisor
configure_nginx_gunicorn
configure_nginx_daphne

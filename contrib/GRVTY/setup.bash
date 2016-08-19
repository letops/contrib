#!/usr/bin/env bash
# Configurations not included: Webpack, Postgresql
# NOTE: lets hope this bash file is replaced by the wercker.yml file someday or something

interactive=
nodejs_bool=false
base_dir_name=GRVTY
project_name=GRVTY
user_name=grvty_user
group_name=grvty_group
giturl=git@github.com:letops/"$project_name".git
first_deployment=false
DANGER=false

function create_user_group
{
  sudo mkdir -p /webapps/"$base_dir_name"
  if [ "$first_deployment" = true ]; then
    sudo mkdir -p /webapps/"$base_dir_name"
    sudo groupadd --system "$group_name"
    sudo useradd --system --gid "$group_name" --shell /bin/bash --home /webapps/"$base_dir_name" "$user_name"
  fi
}

function install_linux_services {
  if [ "$first_deployment" = true ]; then
    sudo apt-get install -y supervisor nginx git
  fi
}

function install_pillow_dependenies {
  if [ "$first_deployment" = true ]; then
    sudo apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk \
        python-imaging python3
    sudo ln -s /usr/include/freetype2 /usr/local/include/freetype
  fi
}

function install_lxml_dependencies {
  if [ "$first_deployment" = true ]; then
    sudo apt-get install libxml2 libxslt1.1 libxml2-dev libxslt1-dev
  fi
}

function install_nodejs_dependencies {
  if [ "$first_deployment" = true ] && [ $nodejs_bool = true ]; then
    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install -g bower
  fi
}

function create_virtualenv {
  if [ "$first_deployment" = true ]; then
    pip3 install virtualenv
    cd /webapps
    virtualenv -p python3 "$base_dir_name"
  fi
}

function configure_database {
  #TODO: Configure Postgresql
  # install postgresql postgresql-contrib postgresql-server-dev-9.3
}

function swap {
  sudo dd if=/dev/zero of=/swapfile bs=1024 count=2048k
  sudo mkswap /swapfile
  sudo swapon /swapfile
  sudo swapon -s
}

function git_clone_install {
  if [ ! whoami = "$username" ]; then
    sudo su - "$user_name"
  fi
  cd
  if [ "$first_deployment" = true ] || [ ! -d "$project_name" ]; then
    # TODO: Generate ssh key as id_rsa_github
    # TODO: Add in .ssh/config the following:
    # host github.com
    #  HostName github.com
    #  IdentityFile ~/.ssh/id_rsa_github
    #  User git

    git clone "$giturl"
  else
    cd "$project_name"
    git pull
    git submodule init
    git submodule update
    cd
  fi
  source bin/activate
  cd "$project_name"
  pip install -r requirements.txt
  logout
}

# NOTE: Generate the file, do not copy it
function configure_gunicorn {
  if [ "$first_deployment" = true ]; then
    sudo su - "$user_name"
    cd
    mkdir -p run
    mkdir -p logs
    touch logs/gunicorn_supervisor.log
    cp "$project_name"/contrib/GRVTY/gunicorn_start.bash bin/gunicorn_start.bash
    chmod u+x bin/gunicorn_start.bash
    nano bin/gunicorn_start.bash
    logout
  fi
}

function collect_static_data {
  sudo su - "$user_name"
  source bin/activate
  cd "$project_name"
  if [ "$nodejs_bool" = true ]; then
    npm install
    bower install
  fi
  python manage.py collectstatic
  logout
}

function reset_permissions {
  if [ "$first_deployment" = true ]; then
    sudo chown "$user_name":"$group_name" /webapps/"$base_dir_name" -R
  fi
}

# NOTE: Generate the file, do not copy it
function configure_supervisor {
  if [ "$first_deployment" = true ]; then
    sudo cp /webapps/"$base_dir_name"/"$project_name"/contrib/GRVTY/grvty.conf /etc/supervisor/conf.d/"$project_name".conf
    sudo nano /etc/supervisor/conf.d/"$project_name".conf
    sudo supervisorctl reread
    sudo supervisorctl update
  fi
  sudo supervisorctl restart "$project_name"
}

# NOTE: Generate the file, do not copy it
function configure_nginx {
  if [ "$first_deployment" = true ]; then
    sudo cp /webapps/"$base_dir_name"/"$project_name"/contrib/GRVTY/grvty.nginxconfig /etc/nginx/sites-available/"$project_name".nginxconf
    sudo nano /etc/nginx/sites-available/"$project_name".nginxconf
    sudo ln -s /etc/nginx/sites-available/"$project_name".nginxconf /etc/nginx/sites-enabled/"$project_name".nginxconf
  fi
  sudo service nginx restart
}


#NOTE: NEVER EXECUTE THIS ONE
if [ $DANGER = false ] && [ $DANGER = true ]; then
  #PILLOW
  sudo mkdir -p /webapps/base_dir_name &&
  sudo groupadd --system group_name &&
  sudo useradd --system --gid group_name --shell /bin/bash --home /webapps/base_dir_name user_name &&
  sudo apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev \
      libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk \
      build-dep python-imaging python3 &&
  sudo ln -s /usr/include/freetype2 /usr/local/include/freetype &&
  # NODEJS
  curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash - &&
  sudo apt-get install -y nodejs npm supervisor nginx git &&
  # VIRTUALENV
  pip3 install virtualenv &&
  cd /webapps &&
  virtualenv -p python3 base_dir_name &&
  # GIT CLONE
  sudo su - user_name &&
  cd &&
  git clone giturl &&
  cd project_name &&
  source ../bin/activate &&
  pip install -r requirements.txt &&
  npm install &&
  bower install &&
  mkdir ../run &&
  mkdir ../logs &&
  touch ../logs/gunicorn_supervisor.log &&
  cp deploy/gunicorn_start.bash ../bin/gunicorn_start.bash &&
  chmod u+x ../bin/gunicorn_start.bash &&
  nano ../bin/gunicorn_start.bash &&
  python manage.py collectstatic &&
  logout &&
  sudo chown user_name:group_name ../../base_dir_name -R
  sudo cp deploy/grvty.conf /etc/supervisor/conf.d/project_name.conf &&
  sudo nano /etc/supervisor/conf.d/project_name.conf &&
  sudo supervisorctl reread &&
  sudo supervisorctl update &&
  sudo cp deploy/grvty.nginxconfig /etc/nginx/sites-available/project_name.nginxconf
  sudo nano /etc/nginx/sites-available/project_name.nginxconf &&
  sudo ln -s /etc/nginx/sites-available/project_name.nginxconf /etc/nginx/sites-enabled/project_name.nginxconf &&
  sudo service nginx restart
fi


function usage
{
  echo -e "\nusage: $0 [-h] | [[-i] [-n] [-d] [-p] [-u] [-g] [-x] ] \n"
  echo -e "\t-f | --first-deploy"
    echo -e "\t\tFlag. Just turn it on in order to generate new users, groups
                files and configurations.\n"

  echo -e "\t-n | --install-node"
    echo -e "\t\tFlag. Just turn it on to install nodejs 4.x and npm.\n"

  echo -e "\t-d string | --base-directory string"
    echo -e "\t\tAdd a string right after the flag. This string represents the
                name of the base directory. This directory will be inside the
                /webapps/ directory.\n"

  echo -e "\t -p string | --project-name string"
    echo -e "\t\tAdd a string right after the flag. This string represents the
                name of the project. This string will be used inside
                configuration files and must be the same as in your GitHub,
                e.g. GRVTY in the url [https://github.com/letops/GRVTY.git].\n"

  echo -e "\t -u string | --user-name string"
  echo -e "\t -g string | --group-name"
  echo -e "\t -x | --git-url"
  echo -e "\t -i | --interactive"
  echo -e "\t -h | --help\n"
}

while [ "$1" != "" ]; do
    case $1 in
        -f | --first-deploy )   first_deployment=true
                                ;;
        -n | --install-node )   nodejs_bool=1
                                ;;
        -d | --base-directory ) shift
                                base_dir_name=$1
                                ;;
        -p | --project-name )   shift
                                project_name=$1
                                ;;
        -u | --user-name )      shift
                                user_name=$1
                                ;;
        -g | --group-name )     shift
                                group_name=$1
                                ;;
        -x | --git-url )        shift
                                giturl=$1
                                ;;
        -i | --interactive )    interactive=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "$interactive" = "1" ]; then
  response=
  echo ""
	echo -e "Interactive is ON. Leave in blank to use the value inside brackets.\n"

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
  echo -n "Is this the first deploy in the server? [y/N] > "
  read response
  case $response in
    [yY][eE][sS]|[yY])
        first_deployment=true
        echo "Create my first deploy"
        echo ""
        ;;
    *)
        first_deployment=false
        echo "NO, just update my deploy"
        echo ""
        ;;
  esac

  echo -n "Do you wish to install NodeJS and the NPM dependencies? [y/N] > "
  read response
  case $response in
    [yY][eE][sS]|[yY])
        nodejs_bool=true
        echo "Install nodejs and npm dependencies, please."
        ;;
    *)
        nodejs_bool=false
        echo "Don't you dare to install that."
        ;;
  esac
else
  usage
  exit 1
fi


if [ "$DANGER" = false ]; then
  create_user_group
  install_linux_services
  install_pillow_dependenies
  install_lxml_dependencies
  install_nodejs_dependencies
  create_virtualenv
  git_clone_install
  configure_gunicorn
  collect_static_data
  reset_permissions
  configure_supervisor
  configure_nginx
fi

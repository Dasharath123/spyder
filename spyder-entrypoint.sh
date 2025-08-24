#!/bin/bash

# Configurations and init scripts 
SPYDERHOME="/home/spyuser"
conda config --system --remove-key pkgs_dirs || true
conda config --system --append pkgs_dirs $SPYDERHOME/.conda/pkgs
conda config --system --append pkgs_dirs /opt/conda/pkgs
conda config --system --remove-key envs_dirs || true
conda config --system --append envs_dirs $SPYDERHOME/.conda/envs
conda config --system --append envs_dirs /opt/conda/envs
conda config --system --set ssl_verify /opt/conda/ssl/cacert.pem
conda config --system --set allow_softlinks true
conda config --system --set always_copy false
conda config --system --set auto_update_conda false
conda config --system --set notify_outdated_conda false

CONDARC_FILE="/opt/conda/.condarc"
DEFAULT_LIST="(default_channels:\\s*\\n(\\s*\\-.*\\n*)+)"
DEFAULT_EMPTY="(default_channels:\\s*\\[\\s*\\]\\s*\\n)"
CUSTOM_OBJECT="(custom_channels:\\s*\\n(\\s+.*\\n*)+)"
CUSTOM_EMPTY="(custom_channels:\\s*{\\s*}\\s*\\n)"

#These commands make sure we do not have the "defaults" channel in the conda config,
# and that the default_channels and custom_channels fields are empty.
#These use "perl" instead of "sed" as it handles multiple lines better.
#The regex will match a list in yaml format, or an empty list ([]).
conda config --system --remove channels defaults || true
conda config --remove channels defaults || true
perl -0777 -i -pe 's/$DEFAULT_LIST//;' $CONDARC_FILE
perl -0777 -i -pe 's/$DEFAULT_EMPTY//;' $CONDARC_FILE
perl -0777 -i -pe 's/$CUSTOM_OBJECT//;' $CONDARC_FILE
perl -0777 -i -pe 's/$CUSTOM_EMPTY//;' $CONDARC_FILE

# Ensure that git fetches can work in more firewall-constrained environments.
git config --global url."https://github.com/".insteadOf git@github.com &&\
    git config --global url."https://".insteadOf git://

# Initialize environment if it's not ready (modifies .bashrc in order to provide needed variables for user session)
# Core commands, like `conda create` and `conda install`, necessarily interact with the shell environment.
#echo "Initialize conda environment"
#conda init bash

# Run the container startup script
. /usr/bin/docker-entrypoint.sh "$@"

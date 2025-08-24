FROM danielguerra/ubuntu-xrdp:latest
LABEL maintainer "Dasharath Middela <dasharath.ny@unilever.com>"

# The conda installation in this file is mostly inspired by:
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Miniforge:
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
# Check https://github.com/conda-forge/miniforge/releases
# Conda version
ARG conda_version="4.9.2"
# Miniforge installer patch version
ARG miniforge_patch_number="5"
# Miniforge installer architecture
ARG miniforge_arch="x86_64"
# Python implementation to use 
# can be either Miniforge3 to use Python or Miniforge-pypy3 to use PyPy
ARG miniforge_python="Miniforge3"

# Miniforge archive to install
ARG miniforge_version="${conda_version}-${miniforge_patch_number}"
# Miniforge installer
ARG miniforge_installer="${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh"
# Miniforge checksum
ARG miniforge_checksum="49dddb3998550e40adc904dae55b0a2aeeb0bd9fc4306869cc4a600ec4b8b47c"

ENV PYTHONPATH "${PYTHONPATH}:/usr/local/lib/python3.7/site-packages:/app" 

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
  sudo \
  apt-utils \
  wget \
  locales \
  gdebi-core \
  gfortran \
  gcc \
  build-essential \
  unzip \
  cmake

# Make sure the en_US line is uncommented in the locale file.
RUN sed -i '/^#.* en_US.UTF-8 /s/^#//' /etc/locale.gen; locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
  SHELL=/bin/bash
ENV PATH=$CONDA_DIR/bin:$PATH \
  CONDA_VERSION="${conda_version}" \
  MINIFORGE_VERSION="${miniforge_version}"

RUN mkdir -p $CONDA_DIR

# Prerequisites installation: conda, pip, tini
RUN wget --quiet "https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/${miniforge_installer}" && \
  echo "${miniforge_checksum} *${miniforge_installer}" | sha256sum --check && \
  /bin/bash "${miniforge_installer}" -f -b -p $CONDA_DIR && \
  rm "${miniforge_installer}" && \
  # Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html
  echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
  conda config --system --set auto_update_conda false && \
  conda config --system --set show_channel_urls true && \
  if [ ! $PYTHON_VERSION = 'default' ]; then conda install --yes python=$PYTHON_VERSION; fi && \
  conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
  conda install --quiet --yes \
  "conda=${CONDA_VERSION}" \
  'pip' \
  'tini=0.18.0' && \
  conda update --all --quiet --yes && \
  conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
  conda clean --all -f -y

COPY ./.condarc ${CONDA_DIR}

RUN apt-get update && apt-get install -y \ 
  python3-numpy \
  python3-matplotlib \
  ipython3 \
  python3-sympy \
  python3-nose \
  libjs-jquery \
  libjs-mathjax \
  python3-pyqt4 \
  tortoisehg \
  gitk \
  python3-pep8 \
  pyflakes \
  pylint \
  python3-jedi \
  python3-psutil \
  python3-sphinx \
  python3-pip \
  libopencv-dev \
  python3-opencv

RUN pip install seaborn python-dateutil dask python-igraph && \
    pip install pyyaml joblib husl geopy ml_metrics mne pyshp && \
    pip install pandas && \
    pip install xgboost && \
    pip install scipy && \
    pip install scikit-learn && \
    pip install spyder && \
    pip install hspfbintoolbox && \
    pip install swmmtoolbox && \
    pip install flopy && \
    pip install Pillow && \
    pip install plotly && \
    pip install dash && \
    pip install rope_py3k

WORKDIR /

# openssl passwd -1 -salt datalab spyderadmin
# openssl passwd -1 -salt datalab spyderuser
RUN echo '999 spadmin $1$datalab$sC9W3f2VtYAOAwJ0I0FBE. sudo' > /etc/users.list \
    && echo '998 spuser $1$datalab$U7kwnr9vrTZCGu6hdK0dE0' >> /etc/users.list

# Add conda to the global path
RUN echo 'PATH=$PATH:/opt/conda/bin' >> /etc/profile

COPY launchers/spyder.desktop /usr/share/applications/spyder.desktop

# Remove firefox and add chromium as default browser ###########
RUN apt-get -yy autoremove firefox \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg \
  && apt-get clean -y \
  && ln -s /usr/bin/chromium-browser /usr/bin/google-chrome \
  && update-alternatives --install /usr/bin/x-www-browser  x-www-browser /usr/bin/chromium-browser 100 \
  && rm -rf /var/lib/apt/lists/*

# These packages are required for Chromium root certificate install 
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends libnss3-tools \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# This will disable the auto screen locking.
RUN apt-get -yy autoremove xautolock \
  && apt-get -yy autoremove xscreensaver \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get clean \
  && apt-get purge

# cleanup of files from setup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy in the startup script
COPY spyder-entrypoint.sh /usr/bin/

# This is a slightly modified version of the create users script in the base image
COPY create-users.sh /usr/bin/

EXPOSE 3389 22
ENTRYPOINT ["/usr/bin/spyder-entrypoint.sh"]
CMD ["supervisord"]

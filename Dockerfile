#
# Base
#

FROM ubuntu:14.04
MAINTAINER yymm yuya.yano.6260@gmail.com

RUN apt-get update -y
RUN chmod go+w,u+s /tmp

# package
RUN apt-get install openssh-server zsh tmux build-essential -y
RUN apt-get install wget unzip curl tree grep bison libssl-dev openssl zlib1g-dev -y # "libssl-dev openssl zlib1g-dev" need to rbenv and pyenv

#vim
RUN apt-get install git mercurial gettext libncurses5-dev  libperl-dev python-dev python3-dev ruby-dev lua5.2 liblua5.2-dev luajit libluajit-5.1 -y
RUN cd /tmp \
    && git clone https://github.com/vim/vim.git \
    && cd /tmp/vim \
    && ./configure --with-features=huge --enable-perlinterp --enable-pythoninterp --enable-python3interp --enable-rubyinterp --enable-luainterp --with-luajit --enable-fail-if-missing \
    && make \
    && make install

# sshd config
RUN sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd
RUN mkdir /var/run/sshd

# user
RUN echo 'root:root' |chpasswd
RUN useradd -m yymm \
    && echo "yymm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo 'yymm:yymm' | chpasswd
RUN chsh -s /usr/bin/zsh yymm

USER yymm
WORKDIR /home/yymm
ENV HOME /home/yymm

# ssh
RUN mkdir .ssh
RUN chmod 700 .ssh
ADD id_rsa ~/.ssh/id_rsa
ADD id_rsa.pub ~/.ssh/id_rsa.pub
USER root
RUN chown yymm /home/yymm/.ssh/id_rsa
RUN chown yymm /home/yymm/.ssh/id_rsa.pub
USER yymm

# dotfiles
RUN git clone https://github.com/yymm/dotfiles.git ~/dotfiles \
    && cd ~/dotfiles \
    && git checkout os/ubuntu-docker \
    && bash bootstrap.sh

#
# Database
#

USER root
# SQLite
RUN apt-get install sqlite3 libsqlite3-dev -y
# client
RUN apt-get install mysql-client redis-tools postgresql-client mongodb-clients -y
USER yymm

#
# Programming Language
#

# Clang (3.5)
USER root
RUN apt-get install clang-3.5 -y
USER yymm

# Ruby (rbenv)
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN cd ~/.rbenv && src/configure && make -C src
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.zshrc
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN ~/.rbenv/bin/rbenv install 2.2.4
RUN ~/.rbenv/bin/rbenv install 1.9.3-p551

# Python (virtualenv)
USER root
RUN apt-get install python-pip -y
RUN pip install virtualenv
RUN pip install virtualenvwrapper
USER yymm
RUN echo 'export WORKON_HOME=$HOME/.virtualenvs' >> ~/.zshrc
RUN echo 'source `which virtualenvwrapper.sh`' >> ~/.zshrc

# Python (pyenv)
RUN git clone https://github.com/yyuu/pyenv.git ~/.pyenv
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
RUN echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
RUN echo 'eval "$(pyenv init -)"' >> ~/.zshrc
RUN ~/.pyenv/bin/pyenv install 3.5.1
RUN ~/.pyenv/bin/pyenv install 2.7.11

# Golang (1.5)
USER root
RUN wget https://storage.googleapis.com/golang/go1.5.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.5.linux-amd64.tar.gz
RUN rm -f go1.5.linux-amd64.tar.gz
USER yymm
RUN echo 'export GOROOT="/usr/local/go"' >> ~/.zshrc
RUN echo 'export PATH="$GOROOT/bin:$PATH"' >> ~/.zshrc

# Node.js (nvm)
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
ENV NODE_VERSION 5.4.0
ENV NVM_DIR $HOME/.nvm
RUN . ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g gulp yo hubot coffee-script browserify

#
# Else
#

# volumes
USER yymm
RUN mkdir /home/yymm/works

# for ssh
USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

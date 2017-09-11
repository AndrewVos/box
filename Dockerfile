FROM ubuntu

RUN apt-get -y update
RUN apt-get -y install sudo
RUN apt-get -y install software-properties-common
RUN useradd -ms /bin/bash test-user
RUN echo '%test-user ALL=(ALL) NOPASSWD: NOPASSWD: ALL' >> /etc/sudoers

USER test-user

ADD . /home/test-user/box
WORKDIR /home/test-user/box

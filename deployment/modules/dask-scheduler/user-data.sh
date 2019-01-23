#!/usr/bin/env bash
echo export DASK_SCHEDULER_IP="${private_scheduler_ip}" >> /etc/profile

sudo yum install python36 python36-devel git gcc -y

sudo rm /usr/bin/python
sudo ln -s /etc/alternatives/python3 /usr/bin/python

sudo pip-3.6 install jupyterlab dask distributed pandas numpy s3fs bokeh
git clone https://github.com/naxty/ecs-dask-blog.git
dask-scheduler ---host ${private_scheduler_ip}&

jupyter lab --LabApp.token='' --ip=0.0.0.0
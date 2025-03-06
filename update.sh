#!/bin/sh
incus file pull docker/root/trafficserver-deb-docker/trafficserver-10.0.2-2hn1ubuntu24.04.tar.gz .
rm -rf trafficserver-10.0.2-2hn1ubuntu24.04
tar xf trafficserver-10.0.2-2hn1ubuntu24.04.tar.gz
sudo apt install --reinstall ./trafficserver-10.0.2-2hn1ubuntu24.04/trafficserver_10.0.2-2hn1ubuntu24.04_amd64.deb \
	./trafficserver-10.0.2-2hn1ubuntu24.04/trafficserver-experimental-plugins_10.0.2-2hn1ubuntu24.04_amd64.deb
sudo cp $HOME/ats10-my-config/* /opt/trafficserver/etc/
sudo systemctl restart trafficserver
systemctl status trafficserver

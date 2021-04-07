FROM hwdsl2/ipsec-vpn-server
LABEL maintainer="Marc Lefkon"

COPY ./run.nas.sh /opt/src/run.nas.sh
RUN chmod 755 /opt/src/run.nas.sh
CMD ["/opt/src/run.nas.sh"]

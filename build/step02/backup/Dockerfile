FROM ubuntu:focal

RUN apt-get update \
    && apt-get -y install lsb-release cron \
    && touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log

# kill interactive prompt for timezone when installing
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

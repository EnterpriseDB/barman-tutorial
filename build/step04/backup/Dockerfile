FROM shog9/barmantutorials:step03-backup

COPY --chown=barman barman/pg.tar.gz /var/lib/barman/

# don't allow running barman until entrypoint script has completed initialization
COPY initcheck.sh /usr/local/bin/barman
RUN chmod +x /usr/local/bin/barman

ADD step04-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/step04-entrypoint.sh
ENTRYPOINT ["step04-entrypoint.sh"]
CMD tail -f /var/log/cron.log

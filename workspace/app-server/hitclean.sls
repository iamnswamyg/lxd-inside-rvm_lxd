/etc/cron.d/ufcleanup-ufo:
  file.managed:
    - name: /etc/cron.d/hitclean
    - source: salt://cron/cron.d/hitclean
    - user: root
    - group: root
    - mode: 644

/usr/local/bin/hitclean.sh:
  file.managed:
    - name: /usr/local/bin/hitclean.sh
    - source: salt://cron/bin/hitclean.sh
    - user: root
    - group: root
    - mode: 700


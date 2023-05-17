rsyslog:
  service:
    - running
    - name: rsyslog
    - enable: True
    - restart: True

/etc/rsyslog.d/35-remote-client.conf:
  file.managed:
    - name: /etc/rsyslog.d/35-remote-client.conf
    - source: salt://rsyslog/rsyslog.d/35-remote-client.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: rsyslog


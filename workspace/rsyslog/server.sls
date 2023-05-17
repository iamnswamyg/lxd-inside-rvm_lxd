rsyslog:
  service:
    - running
    - name: rsyslog
    - enable: True
    - restart: True
{%- if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 20 %}
    - watch:
      - /var/log/rsyslog
{%- endif %}

/etc/rsyslog.d/30-remote-server.conf:
  file.managed:
    - name: /etc/rsyslog.d/30-remote-server.conf
    - source: salt://rsyslog/rsyslog.d/30-remote-server.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: rsyslog

{%- if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 20 %}
/var/log/rsyslog:
  file.directory:
    - user: syslog
    - group: syslog
    - dir_mode: 700
{%- endif %}
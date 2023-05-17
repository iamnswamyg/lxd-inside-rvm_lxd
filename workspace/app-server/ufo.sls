{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/etc/cron.d/ufcleanup-ufo:
  file.managed:
    - name: /etc/cron.d/ufcleanup-ufo
    - source: salt://cron/cron.d/ufcleanup-ufo
    - user: root
    - group: root
    - mode: 644

/usr/local/bin/ufcleanup-ufo.sh:
  file.managed:
    - name: /usr/local/bin/ufcleanup-ufo.sh
    - source: salt://cron/bin/ufcleanup-ufo.sh
    - user: root
    - group: root
    - mode: 700

{% if network['site'] == 'ufcolo1' or network['site'] == 'ufcolo2' %}
/etc/cron.d/ufmove-ufo-orders:
  file.managed:
    - name: /etc/cron.d/ufmove-ufo-orders
    - source: salt://cron/cron.d/ufmove-ufo-orders
    - user: root
    - group: root
    - mode: 644

/usr/local/bin/ufmove-ufo-orders.sh:
  file.managed:
    - name: /usr/local/bin/ufmove-ufo-orders.sh
    - source: salt://cron/bin/ufmove-ufo-orders.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        target_dir: /net/glusterfs/ufoweb/orders

/etc/cron.d/ufcleanup-ufo-log:
  file.managed:
    - name: /etc/cron.d/ufcleanup-ufo-log
    - source: salt://cron/cron.d/ufcleanup-ufo-log
    - user: root
    - group: root
    - mode: 644

/usr/local/bin/ufcleanup-ufo-log.sh:
  file.managed:
    - name: /usr/local/bin/ufcleanup-ufo-log.sh
    - source: salt://cron/bin/ufcleanup-ufo-log.sh
    - user: root
    - group: root
    - mode: 700
{% endif %}

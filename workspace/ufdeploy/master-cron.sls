{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/etc/cron.d/ufmaster-switch:
  file.managed:
    - name: /etc/cron.d/ufmaster-switch
    - source: salt://cron/cron.d/ufmaster-switch
    - user: root
    - group: root
    - mode: 644

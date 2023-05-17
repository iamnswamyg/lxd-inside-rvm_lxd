{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/usr/local/bin/ufactivate-site-dns.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-site-dns.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-site-dns.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        site: {{ network['site'] }}

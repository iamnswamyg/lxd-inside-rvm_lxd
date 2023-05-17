{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/usr/local/bin/ufactivate-app-apache.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-app-apache.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-app-apache.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufactivate-site-apache.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-site-apache.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-site-apacheanddns.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        site: {{ network['site'] }}

/usr/local/bin/ufdeploy-apache.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-apache.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufdeploy-apache.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufundeploy-apache.sh:
  file.managed:
    - name: /usr/local/bin/ufundeploy-apache.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufundeploy-apache.sh
    - user: root
    - group: root
    - mode: 700

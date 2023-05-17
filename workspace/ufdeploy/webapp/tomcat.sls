{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/usr/local/bin/ufactivate-app-tomcat.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-app-tomcat.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-app-tomcat.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        colo_site: {{ network['site'] }}

/usr/local/bin/ufswitchover-app.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-app.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-app.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufswitchover-tomcat.sh:
  file.absent:
    - name: /usr/local/bin/ufswitchover-tomcat.sh
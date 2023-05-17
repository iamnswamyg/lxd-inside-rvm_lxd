{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

/usr/local/bin/ufactivate-ee-app.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-ee-app.sh
    - source: salt://ufdeploy/ee/ufactivate/ufactivate-ee-app.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        colo_site: {{ network['site'] }}

/usr/local/bin/ufdeploy-ee-app.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-ee-app.sh
    - source: salt://ufdeploy/ee/ufdeploy/ufdeploy-ee-app.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    
ee/usr/local/bin/ufswitchover-app.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-app.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-app.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufswitchover-ee-app.sh:
  file.absent:
    - name: /usr/local/bin/ufswitchover-ee-app.sh

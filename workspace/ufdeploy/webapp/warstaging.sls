/usr/local/bin/ufdeploy-tomcat.sh:
  file.absent:
    - name: /usr/local/bin/ufdeploy-tomcat.sh

/usr/local/bin/ufdeploy-warstaging.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-warstaging.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufdeploy-warstaging.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja

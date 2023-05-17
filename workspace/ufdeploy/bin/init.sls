/usr/local/bin/ufdeploy-synchronizer:
  file.managed:
    - name: /usr/local/bin/ufdeploy-synchronizer
    - source: salt://ufdeploy/bin/ufdeploy-synchronizer
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufdeploy-coordinator:
  file.managed:
    - name: /usr/local/bin/ufdeploy-coordinator
    - source: salt://ufdeploy/bin/ufdeploy-coordinator
    - user: root
    - group: root
    - mode: 700


/usr/local/bin/ufswitchover-pgsql-promote.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-pgsql-promote.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-pgsql-promote.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufswitchover-pgsql-demote.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-pgsql-demote.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-pgsql-demote.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufbasebackup.sh:
  file.managed:
    - name: /usr/local/bin/ufbasebackup.sh
    - source: salt://ufdeploy/webapp/misc/ufbasebackup.sh
    - user: root
    - group: root
    - mode: 700


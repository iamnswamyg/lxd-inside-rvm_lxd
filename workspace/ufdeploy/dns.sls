/usr/local/bin/ufdeploy-dns.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-dns.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufdeploy-dns.sh
    - user: root
    - group: root
    - mode: 700


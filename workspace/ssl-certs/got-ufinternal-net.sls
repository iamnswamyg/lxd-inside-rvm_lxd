/etc/ssl/certs/got_ufinternal_net.crt:
  file.managed:
    - name: /etc/ssl/certs/got_ufinternal_net.crt
    - user: root
    - group: root
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.crt
    - mode: 644

/etc/ssl/certs/got_ufinternal_net.intermediate.crt:
  file.managed:
    - name: /etc/ssl/certs/got_ufinternal_net.intermediate.crt
    - user: root
    - group: root
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.intermediate.crt
    - mode: 644

/etc/ssl/private/got_ufinternal_net.key:
  file.managed:
    - name: /etc/ssl/private/got_ufinternal_net.key
    - contents_pillar: ufconfig:apachecertkeys:got_ufinternal_net.key
    - user: root
    - group: ssl-cert
    - mode: 640
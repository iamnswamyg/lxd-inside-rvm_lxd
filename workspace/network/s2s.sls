/etc/netplan/03-netcfg-s2s.yaml:
  file.managed:
    - source: salt://network/03-netcfg-s2s.yaml
    - template: jinja
    - user: root
    - mode: 644
    - context:
      vlan_link: bond0
  cmd.wait:
    - name: '/usr/sbin/netplan apply'
    - user: root
    - watch:
        - file: /etc/netplan/03-netcfg-s2s.yaml
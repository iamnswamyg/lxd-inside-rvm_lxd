/etc/netplan/01-netcfg.yaml:
  file.managed:
    - source: salt://network/01-netcfg-vm.yaml
    - template: jinja
    - user: root
    - mode: 644
  cmd.wait:
    - name: '/usr/sbin/netplan apply'
    - user: root
    - watch:
      - file: /etc/netplan/01-netcfg.yaml

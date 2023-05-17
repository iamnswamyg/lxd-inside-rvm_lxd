{% if grains['osfinger'] == 'Ubuntu-14.04' %}
/etc/network/interfaces:
  file:
    - managed
    - source: salt://network/interfaces_vhost
    - template: jinja
{% endif %}

{% if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 18 %}
{% if grains['virtual'] != 'physical' %}
/etc/netplan/remove-temp-yaml:
  file.absent:
    - names:
      - /etc/netplan/50-cloud-init.yaml
      - /etc/netplan/00-installer-config.yaml
{% endif %}

/etc/netplan/01-netcfg.yaml:
  file.managed:
    - source: salt://network/01-netcfg-vhost.yaml
    - template: jinja
    - user: root
    - mode: 644
  cmd.wait:
    - name: '/usr/sbin/netplan apply'
    - user: root
    - watch:
      - file: /etc/netplan/01-netcfg.yaml

restart-salt-minion-service:
  service.running:
    - name: salt-minion
    - watch:
      - file: /etc/netplan/01-netcfg.yaml
{% endif %}

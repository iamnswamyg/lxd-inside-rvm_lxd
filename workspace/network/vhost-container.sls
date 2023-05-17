{% if grains['osfinger'] == 'Ubuntu-14.04' %}
/etc/network/interfaces:
  file:
    - managed
    - source: salt://network/interfaces_vhost
    - template: jinja
{% endif %}

{% if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 18 %}
{% if grains['virtual'] != 'physical' %}
remove-yaml:
  file.absent:
    - names:
      - /etc/netplan/50-cloud-init.yaml
      - /etc/netplan/00-installer-config.yaml
      - /etc/netplan/01-netcfg.yaml

/etc/netplan/99-netcfg.yaml:
  file.managed:
    - source: salt://network/single-if.yaml
    - template: jinja
    - user: root
    - mode: 644
  cmd.wait:
    - name: '/usr/sbin/netplan apply'
    - user: root
    - watch:
      - file: /etc/netplan/99-netcfg.yaml

{#
  This state previously restarted the salt-minion service.
  This caused issues and is probably not necessary, so it has been removed.
#}

{% endif %}
{% endif %}
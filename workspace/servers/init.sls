man-db:
  pkg:
    - installed

nano:
  pkg:
    - installed

pigz:
  pkg:
    - installed

{# 
    Debian 11/Ubuntu 22 package is called python3-pycurl
    The reason for installing this package is unclear.
#}

{% if grains['osfinger'] == 'Debian-11' or grains['osfinger'] == 'Ubuntu-22.04' %}
python3-pycurl:
  pkg:
    - installed
{% else %}
python-pycurl:
  pkg:
    - installed
{% endif %}

curl:
  pkg:
    - installed

{% if grains['osfinger'] == 'Ubuntu-18.04' %}
jq:
  pkg:
    - installed
{% endif %}

{% if grains['osfinger'] == 'Ubuntu-14.04' %}
python-software-properties:
  pkg:
    - installed
{% endif %}

{% if grains['osfinger'] == 'Ubuntu-14.04' and grains['virtual'] == 'VMware' %}
open-vm-tools:
  pkg:
    - installed
{% endif %}

iperf:
  pkg:
    - installed

sysstat:
  pkg:
    - installed

{% if grains['virtual'] == 'physical' %}
atop:
  pkg:
    - installed
{% endif %}

unzip:
  pkg:
    - installed

dnsutils:
  pkg:
    - installed

{%- if 'gluster' not in grains['id'] and 'backup' not in grains['id'] %}
rpcbind:
  pkg:
    - removed
{%- endif %}

#sv_SE.UTF-8:
#  locale.present

#en_US.UTF-8:
#  locale.present

ip-127.0.1.1:
  host.absent:
    - ip: 127.0.1.1

{% set host = pillar['ufconfig']['hosts'][grains.id] %}
#{{ grains.id }}_fqnhost:
#  host.present:
#    - ip: {{ host['networking']['address'] }}
#    - name: {{ grains.id }}

# Disable IPv6
net.ipv6.conf.all.disable_ipv6:
  sysctl.present:
    - value: 1
net.ipv6.conf.default.disable_ipv6:
  sysctl.present:
    - value: 1
net.ipv6.conf.lo.disable_ipv6: 
  sysctl.present:
    - value: 1

{% if 'sysctl' in host %}
{% set hostSysctl = host['sysctl'] %}
{% for conf in (hostSysctl if (hostSysctl | is_list) else [hostSysctl]) %}
{% set sysctl = pillar['ufconfig']['sysctl'][conf] %}
{% for name in sysctl %}
{{ name }}:
  sysctl.present:
    - value: {{ sysctl[name] }}
{% endfor %}
{% endfor %}
{% endif %}

{% if grains['manufacturer'] != 'Amazon EC2' %}

{% for name in pillar['ufconfig']['hosts'] %}
{% set host = pillar['ufconfig']['hosts'][name] %}
{% if 'hidden' not in host or not host['hidden'] == True %}
{{ name }}_host:
{% if 'absent' in host and host['absent'] == True %}
  host.absent:
    - ip: {{ host['networking']['address'] }}
    - names:
      - {{ host['networking']['hostname'] }}.ufprod.lan
      - {{ host['networking']['hostname'] }}.got.ufinternal.net
      - {{ host['networking']['hostname'] }}
{% else %}
  host.present:
    - ip: {{ host['networking']['address'] }}
    - names:
      - {{ host['networking']['hostname'] }}.ufprod.lan
      - {{ host['networking']['hostname'] }}.got.ufinternal.net
      - {{ host['networking']['hostname'] }}
    - clean: True
{% endif %}
{% endif %}
{% endfor %}

{% else %}

/etc/hosts:
  file.managed:
    - name: /etc/hosts
    - source: salt://servers/hosts.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja

{% endif %}

{% if grains['osfinger'] == 'Ubuntu-14.04' %}
apt-repo:
  file.replace:
    - name: /etc/apt/sources.list
    - pattern: 'deb http://ufoffice-aptrepo.ufprod.lan debs/'
    - repl: ''
    - backup: false
    - show_changes: true
#  pkgrepo.absent:
#    - name: 'deb http://ufoffice-aptrepo.ufprod.lan debs/'

aptly-repo:
  pkgrepo.absent:
    - name: deb http://ufoffice-aptly.ufprod.lan/trusty trusty main
{% endif %}

{% if grains['osfinger'] == 'Ubuntu-18.04' %}
aptly-repo-old:
  pkgrepo.absent:
    - name: deb http://ufoffice-aptly.ufprod.lan bionic-pgdg main


aptly-repo:
  file.absent:
    - name: /etc/apt/sources.list.d/source1.list
  pkgrepo.absent:
    - name: deb http://ufoffice-aptly.ufprod.lan/bionic bionic main

{% endif %}

{#  
    Ubuntu 20 requires you to specifically use "python2" or "python3", so a script trying to use
    the command "python" will fail. python2 has been removed from Ubuntu 20, so we'll use python3.
    
    By installing 'python-is-python3' the command 'python' will point at python3. This may cause
    code to fail that expects python2, but that code would already fail anyway, and if it does
    work fine with python3, that's better than not even trying.
#}

{% if grains['osfinger'] == 'Ubuntu-20.04' %}

point-python-to-python3:
  pkg.installed:
    - name: python-is-python3
    - creates:
      - /usr/bin/python

{% endif %}

{% if grains['osfinger'] >= 'Ubuntu-18.04' %}
include:
  - repos.saltstack-repo
{% endif %}

/etc/profile.d/timeout.sh:
  file.absent:
    - name: /etc/profile.d/timeout.sh

/etc/cron.daily/logrotate:
  file.rename:
    - name: /etc/cron.hourly/logrotate
    - source: /etc/cron.daily/logrotate
    - force: True

/etc/logrotate.d/:
  file.recurse:
    - name: /etc/logrotate.d
    - user: root
    - group: root
    - source: salt://servers/logrotate.d
    - template: jinja
    - file_mode: 644

Europe/Stockholm:
  timezone.system

/etc/salt/minion.d/salt-minion.conf:
  file.managed:
    - source: salt://servers/salt-minion.conf
    - user: root
    - group: root
    - mode: 644

{% if grains['virtual'] == 'LXC' and grains['osfinger'] == 'Ubuntu-18.04' %}
# Disable services that fail to start on ubuntu 18.04 lxc container

/etc/systemd/system/sys-kernel-config.mount.d/container.conf:
  file.managed:
    - name: /etc/systemd/system/sys-kernel-config.mount.d/container.conf
    - source: salt://servers/lxd/container.conf
    - makedirs: True
    - user: root
    - group: root
    - mode: 644

/etc/systemd/system/systemd-modules-load.service.d/container.conf:
  file.managed:
    - name: /etc/systemd/system/systemd-modules-load.service.d/container.conf
    - source: salt://servers/lxd/container.conf
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
{% endif %}
{% if grains['osfinger'] != 'Ubuntu-14.04' %}
sv_SE_locale:
  locale.present:
    - name: sv_SE.UTF-8
en_GB_locale:
  locale.present:
    - name: en_GB.UTF-8
en_US_locale:
  locale.present:
    - name: en_US.UTF-8
sv_FI_locale:
  locale.present:
    - name: sv_FI.UTF-8
fi_FI_locale:
  locale.present:
    - name: fi_FI.UTF-8
da_DK_locale:
  locale.present:
    - name: da_DK.UTF-8
nn_NO_locale:
  locale.present:
    - name: nn_NO.UTF-8
nb_NO_locale:
  locale.present:
    - name: nb_NO.UTF-8

default_locale:
  locale.system:
    - name: en_US.UTF-8
    - require:
      - locale: en_US_locale
{% endif %}

{% if grains['saltversion'] == '2019.2.0' %}
/usr/lib/python2.7/dist-packages/salt/states/host.py:
  file.managed:
    - name: /usr/lib/python2.7/dist-packages/salt/states/host.py
    - source: salt://servers/salt-minion/host.py
    - user: root
    - group: root
    - mode: 644
/usr/lib/python2.7/dist-packages/salt/output/highstate.py:
  file.managed:
    - name: /usr/lib/python2.7/dist-packages/salt/output/highstate.py
    - source: salt://servers/salt-minion/highstate.py
    - user: root
    - group: root
    - mode: 644
{% endif %}

{% if 'nofile_limit' in host %}
/etc/security/limits.conf:
  file.managed:
    - name: /etc/security/limits.conf
    - source: salt://servers/limits.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        host_nofile_limit: {{ host['nofile_limit'] }}
{% endif %}

{#
  UNATTENDED UPGRADES
  
  This package seems to be present on multiple Ubuntu versions,
  including Ubuntu 18.
  
  Since we handle patching manually, it seems strange to have
  unattended upgrades enabled. This section removes it on Ubuntu 18+.
#}

{%- if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 18 %}

purge-unattended-upgrades:
  pkg.purged:
    - name: unattended-upgrades

{% endif %}

{%- if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] >= 18 %}
salt-minion-service-override:
  file.managed:
    - name: /etc/systemd/system/salt-minion.service.d/override.conf
    - source: salt://servers/salt-minion/override.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/salt-minion.service.d/override.conf
{%- endif %}

{% if grains['manufacturer'] == 'Amazon EC2' and grains['host'] != grains['id'] %}
set-hostname:
  cmd.run:
    - name: /usr/bin/hostnamectl set-hostname {{ grains.id }}
{% endif %}
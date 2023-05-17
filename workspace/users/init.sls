{% set host         = pillar['ufconfig']['hosts'][grains.id] %}
{% set ip_address   = host['networking']['address'] %}
{% set hostname     = host['networking']['hostname'] %}
{% set tailscale_ip = host['networking'].get('tailscale-ip',{}) %}
ssh:
  service:
    - running
    - reload: True

/etc/ssh/auth:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - require:
      - service: ssh


## If PasswordAuthentication is on, turn off
/etc/ssh/sshd_config.remove:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PasswordAuthentication yes'
    - repl: 'PasswordAuthentication no'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: ssh

# Append these lines to sshd_config, if not present
/etc/ssh/sshd_config:
  file.append:
    - text:
      - AuthorizedKeysFile /etc/ssh/auth/%u
      - PasswordAuthentication no
      - ChallengeResponseAuthentication no
      - ListenAddress {{ ip_address }}
{%- if hostname == "aws1-salt1" %}
      - PubkeyAcceptedKeyTypes +ssh-rsa
{%- endif %}
{%- if tailscale_ip is defined and tailscale_ip|length %}
      - ListenAddress {{ tailscale_ip }}
{%- endif %}
    - require:
      - file: /etc/ssh/sshd_config.remove
    - watch_in:
      - service: ssh

user_ubuntu:
  user.absent:
    - name: ubuntu
    - purge: True
    - force: True

user_ufadm:
  user.present:
    - name: ufadm
    - uid: 1000
    - fullname: ufadm
    - shell: /bin/bash
    - password: $6$8rYyn21DOrYbQ8iB$LRcpQBkMnnSp/WH6BERImb5.Xr9HxkocECpYT38QbeKWl/Y5BG1y4xAb12xMeuYkTwAQ6c.Hjnodq3ZDJqDjU.
    - groups:
      - sudo

user_dummy:
  user.present:
    - name: dummy
    - uid: 3999
    - fullname: dummy
    - shell: /bin/false
    - home: /bin
{% set users = pillar['ufconfig']['users'] %}
{% for username in users %}
{% set user = users[username] %}

{% if 'state' in user and user['state'] == 'disabled' or not user.get('std-user', True) %}
user_{{ username }}:
  user.absent:
    - name: {{ username }}
  file.absent:
    - name: /etc/ssh/auth/{{ username }}
{% else %} 
user_{{ username }}:
  user.present:
    - name: {{ username }}
    - uid: {{ user['uid'] }}
    - fullname: {{ user['fullname'] }}
    - shell: /bin/bash
    - password: {{ user['password'] }}
    - groups:
      - sudo
  ssh_auth.present:
    - user: {{ username }}
    - config: /etc/ssh/auth/{{ username }}
    - source: salt://users/keys/{{ username }}.id_rsa.pub
    - require:
      - user: {{ username }}
      - file: /etc/ssh/auth
      
#remove_key_user_{{ username }}:
#  ssh_auth.absent:
#    - user: {{ username }}
#    - config: /etc/ssh/auth/{{ username }}
#    - source: salt://users/removed_keys.id_rsa.pub
#    - require:
#      - user: {{ username }}
#      - file: /etc/ssh/auth
      
{% endif %} 
{% endfor %}

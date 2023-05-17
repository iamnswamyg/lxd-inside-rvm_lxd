{% import_yaml tpldir ~ "/workers.yaml" as workersData %}
{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

accepted-mscorefonts-eula:
  debconf.set:
    - name: ttf-mscorefonts-installer
    - data:
        'msttcorefonts/accepted-mscorefonts-eula': {'type': 'boolean', 'value': 'true'}

tomcat9-group:
  group.present:
    - name: tomcat
    - gid: 3991

tomcat9-user:
  user.present:
    - name: tomcat
    - uid: 3991
    - gid: 3991
    - usergroup: True
    - allow_uid_change: True
    - allow_gid_change: True
    - fullname: Tomcat User
    - groups:
      - adm
      - syslog
      - tomcat

tomcat9_packages:
  pkg.installed:
    - pkgs:
      - ttf-mscorefonts-installer
      - libtcnative-1
      - tomcat9
      - tomcat9-admin
      - wget

tomcat9-umask:
  file.replace:
    - name: /usr/share/tomcat9/bin/catalina.sh
    - pattern: 'umask 0227'
    - repl: 'umask 0027' 
    - append_if_not_found: True

tomcat9-service:
  service.running:
    - name: tomcat9
    - enable: True

/etc/tomcat9/tomcat-users.xml:
  file.managed:
    - name: /etc/tomcat9/tomcat-users.xml
    - source: salt://app-server/tomcat-users.xml
    - user: root
    - group: tomcat
    - mode: 640
    - watch_in:
      - service: tomcat9-service

/etc/tomcat9/jmxremote.properties:
  file.managed:
    - name: /etc/tomcat9/jmxremote.properties
    - source: salt://app-server/jmxremote.properties
    - user: tomcat
    - group: tomcat
    - mode: 600
    - template: jinja
    - context:
        tomcat_config_path: /etc/tomcat9
    - watch_in:
      - service: tomcat9-service

/etc/tomcat9/jmxremotessl.properties:
  file.managed:
    - name: /etc/tomcat9/jmxremotessl.properties
    - source: salt://app-server/jmxremotessl.properties
    - user: tomcat
    - group: tomcat
    - mode: 600
    - template: jinja
    - context:
        tomcat_user_home: /var/lib/tomcat9
    - watch_in:
      - service: tomcat9-service

{% if 'tomcat-config-name' in host %}
/etc/tomcat9/server.xml:
  file.managed:
    - name: /etc/tomcat9/server.xml
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/server.xml
    - user: root
    - group: tomcat
    - mode: 644
    - watch_in:
      - service: tomcat9-service
    - template: jinja
{% endif %}

{% if 'tomcat-template-files' in host %}
{% set files = host['tomcat-template-files'] %}
{% for target in files %}
/etc/tomcat9/{{ target }}:
  file.managed:
    - name: /etc/tomcat9/{{ target }}
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat
    - mode: 644
    - replace: false
    - watch_in:
      - service: tomcat9-service
/etc/tomcat9/{{ target }}.template:
  file.managed:
    - name: /etc/tomcat9/{{ target }}.template
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat
    - mode: 644
{% endfor %}
{% endif %}
{% if 'btm-config' in host %}
/etc/tomcat9/btm-config.properties:
  file.managed:
    - name: /etc/tomcat9/btm-config.properties
    - source: salt://app-server/{{ host['btm-config'] }}
    - user: root
    - group: tomcat
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat9-service
{% endif %}
{% if 'btm-resources' in host %}
/etc/tomcat9/btm-resources.properties:
  file.managed:
    - name: /etc/tomcat9/btm-resources.properties
    - source: salt://app-server/{{ host['btm-resources'] }}
    - user: root
    - group: tomcat
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat9-service
{% endif %}

# Used by nio https connector
/var/lib/tomcat9/got_ufinternal_net.full.p12:
  file.managed:
    - name: /var/lib/tomcat9/got_ufinternal_net.full.p12
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.full.p12
    - user: root
    - group: tomcat
    - mode: 640
    - watch_in:
      - service: tomcat9-service

# Used by jmx
/var/lib/tomcat9/tomcat.keystore:
  file.managed:
    - name: /var/lib/tomcat9/tomcat.keystore
    - source: salt://app-server/keystores/server/tomcat.keystore
    - user: root
    - group: tomcat
    - mode: 640
    - watch_in:
      - service: tomcat9-service

/var/lib/tomcat9/tomcat.truststore:
  file.managed:
    - name: /var/lib/tomcat9/tomcat.truststore
    - source: salt://app-server/keystores/server/tomcat.truststore
    - user: root
    - group: tomcat
    - mode: 640
    - watch_in:
      - service: tomcat9-service

/usr/share/tomcat9/bin/setenv.sh:
  file.managed:
    - name: /usr/share/tomcat9/bin/setenv.sh
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/setenv.sh
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat9-service

tomcat9-extra-jars:
  file.recurse:
    - name: /usr/share/tomcat9/lib
    - user: root
    - group: root
    - source: salt://app-server/tomcat9-lib
    - watch_in:
      - service: tomcat9-service

tomcat9-extra-jars-jta:
  file.recurse:
    - name: /usr/share/tomcat9/lib
    - user: root
    - group: root
    - watch_in:
      - service: tomcat9-service
{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
    - source: salt://app-server/tomcat9-lib-narayana
{% else %}
    - source: salt://app-server/tomcat9-lib-btm
{% endif %}

tomcat9-extra-jars-remove:
  file.absent:
    - names:
      - /usr/share/tomcat9/lib/postgresql-42.2.6.jar
      - /usr/share/tomcat9/lib/geronimo-jta_1.0.1B_spec-1.0.1.jar
{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
      - /usr/share/tomcat9/lib/btm-3.0.0-SNAPSHOT-2014-08-22.jar
      - /usr/share/tomcat9/lib/btm-tomcat55-lifecycle-3.0.0-SNAPSHOT-2014-08-22.jar
{% else %}
      - /usr/share/tomcat9/lib/tomcat-narayana-jta-5.9.0.Final.jar
      - /usr/share/tomcat9/lib/log4j-1.2.14.jar
      - /usr/share/tomcat9/lib/commons-pool2-2.10.0.jar
      - /usr/share/tomcat9/lib/commons-logging-1.2.jar
      - /usr/share/tomcat9/lib/commons-dbcp2-2.8.0.jar
{% endif %}

tomcat9-manager-max-deploy-file-size1:
  file.replace:
    - name: /usr/share/tomcat9-admin/manager/WEB-INF/web.xml
    - pattern: '<max-file-size>52428800</max-file-size>'
    - repl: '<max-file-size>-1</max-file-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat9-service

tomcat9-manager-max-deploy-file-size2:
  file.replace:
    - name: /usr/share/tomcat9-admin/manager/WEB-INF/web.xml
    - pattern: '<max-request-size>52428800</max-request-size>'
    - repl: '<max-request-size>-1</max-request-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat9-service

/var/webapp:
  file.directory:
    - name: /var/webapp
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/unifaun:
  file.directory:
    - name: /var/unifaun
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/bobapp:
  file.directory:
    - name: /var/bobapp
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/hitapp:
  file.directory:
    - name: /var/hitapp
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/usr/local/ufofs:
  file.directory:
    - name: /usr/local/ufofs
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/ufoedi:
  file.directory:
    - name: /var/ufoedi
    - user: tomcat
    - group: tomcat
    - mode: 770
    - recurse:
      - user
      - group
      - mode


/etc/cron.d/ufcleanup-webapp:
  file.managed:
    - name: /etc/cron.d/ufcleanup-webapp
    - source: salt://cron/cron.d/ufcleanup-webapp
    - user: root
    - group: root
    - mode: 644

/usr/local/bin/ufcleanup-webapp.sh:
  file.managed:
    - name: /usr/local/bin/ufcleanup-webapp.sh
    - source: salt://cron/bin/ufcleanup-webapp-tomcat9.sh
    - user: root
    - group: root
    - mode: 700

/etc/cron.d/ufrestart-webapp:
  file.managed:
    - name: /etc/cron.d/ufrestart-webapp
    - source: salt://cron/cron.d/ufrestart-webapp
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        restart_cron_min: {{ host['tomcat-restart-cron-min'] }}

{% if network['site'] == 'ufoffice' %}
/usr/local/bin/ufrestart-webapp.sh:
  file.managed:
    - name: /usr/local/bin/ufrestart-webapp.sh
    - source: salt://cron/bin/ufrestart-webapp-simple.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        service: tomcat9
{% else %}
/usr/local/bin/ufrestart-webapp.sh:
  file.managed:
    - name: /usr/local/bin/ufrestart-webapp.sh
    - source: salt://cron/bin/ufrestart-webapp.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        workers: {{ workersData['servers'] | json }}
        calls: {{ host['tomcat-restart-calls'] }}
        service: tomcat9
{% endif %}

# will be set in server/init.sls for ubuntu 18.04
#sv_SE_locale:
#  locale.present:
#    - name: sv_SE.utf8

/var/lib/tomcat9:
  file.directory:
    - group: tomcat
    - recurse:
      - group

/var/lib/tomcat9/webapps:
  file.directory:
    - user: tomcat
    - recurse:
      - user

{% if salt['file.directory_exists' ]('/var/cache/tomcat9') %}
/var/cache/tomcat9:
  file.directory:
    - user: tomcat
    - recurse:
      - user
{% endif %}

{% if salt['file.directory_exists' ]('/var/log/tomcat9') %}
/var/log/tomcat9:
  file.directory:
    - user: tomcat
    - recurse:
      - user
{% endif %}

wait-for-tomcatmanager:
  tomcat.wait:
    - timeout: 300
    - require:
      - service: tomcat9-service

{% if salt['file.directory_exists' ]('/var/lib/tomcat9/webapps/ROOT') %}
owner-/var/lib/tomcat9/webapps/ROOT:
  file.directory:
    - name: /var/lib/tomcat9/webapps/ROOT
    - user: tomcat
    - group: tomcat
    - recurse:
      - user
      - group
    - require:
      - pkg: tomcat9_packages
{% endif %}

{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
/var/lib/tomcat9/ObjectStore:
  file.symlink:
    - name: /var/lib/tomcat9/ObjectStore
    - target: work/Narayana/ObjectStore
    - user: tomcat
    - group: tomcat
{% endif %}

{# Place override file for tomcat 9 service, create dirs if necessary #}
/etc/systemd/system/tomcat9.service.d/override.conf:
  file.managed:
    - name: /etc/systemd/system/tomcat9.service.d/override.conf
    - source: salt://app-server/tomcat9-systemd/tomcat9.service.d/override.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
  module.run:
{# NOTE: systemctl_reload runs 'daemon-reload' but does not restart the service. #}
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/tomcat9.service.d/override.conf

{#
    Remove old tomcat versions
    If tomcat 7/8 is installed on this system, remove it.
    Additionally, make sure the init.d files are actually gone
#}

remove-older-tomcat-versions:
  pkg.removed:
    - pkgs:
      - tomcat7
      - tomcat8

remove-service-files-for-older-tomcat-versions:
  file.absent:
    - names:
      - /etc/init.d/tomcat8
      - /etc/init.d/tomcat7
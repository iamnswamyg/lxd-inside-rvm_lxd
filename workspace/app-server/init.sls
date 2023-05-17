{% import_yaml tpldir ~ "/workers.yaml" as workersData %}
{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

accepted-mscorefonts-eula:
  debconf.set:
    - name: ttf-mscorefonts-installer
    - data:
        'msttcorefonts/accepted-mscorefonts-eula': {'type': 'boolean', 'value': 'true'}
ttf-mscorefonts-installer:
  pkg:
    - installed

libtcnative-1:
  pkg:
    - installed

tomcat7:
  pkg:
    - installed

tomcat-service:
  service.running:
    - name: tomcat7
    - enable: True

wait-for-tomcatmanager:
  tomcat.wait:
    - timeout: 300
    - require:
      - service: tomcat-service

tomcat7-admin:
  pkg:
    - installed

wget:
  pkg:
    - installed

/etc/tomcat7/tomcat-users.xml:
  file.managed:
    - name: /etc/tomcat7/tomcat-users.xml
    - source: salt://app-server/tomcat-users.xml
    - user: root
    - group: tomcat7
    - mode: 640

/etc/tomcat7/jmxremote.properties:
  file.managed:
    - name: /etc/tomcat7/jmxremote.properties
    - source: salt://app-server/jmxremote.properties
    - user: tomcat7
    - group: tomcat7
    - mode: 600
    - template: jinja
    - context:
        tomcat_config_path: /etc/tomcat7

/etc/tomcat7/jmxremotessl.properties:
  file.managed:
    - name: /etc/tomcat7/jmxremotessl.properties
    - source: salt://app-server/jmxremotessl.properties
    - user: tomcat7
    - group: tomcat7
    - mode: 600
    - template: jinja
    - context:
        tomcat_user_home: /usr/share/tomcat7

{% if 'tomcat-config-name' in host %}
/etc/tomcat7/server.xml:
  file.managed:
    - name: /etc/tomcat7/server.xml
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/server.xml
    - user: root
    - group: tomcat7
    - mode: 644
    - template: jinja
{% endif %}

{% if 'tomcat-template-files' in host %}
{% set files = host['tomcat-template-files'] %}
{% for target in files %}
/etc/tomcat7/{{ target }}:
  file.managed:
    - name: /etc/tomcat7/{{ target }}
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat7
    - mode: 644
    - replace: false
/etc/tomcat7/{{ target }}.template:
  file.managed:
    - name: /etc/tomcat7/{{ target }}.template
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat7
    - mode: 644
{% endfor %}
{% endif %}
{% if 'btm-config' in host %}
/etc/tomcat7/btm-config.properties:
  file.managed:
    - name: /etc/tomcat7/btm-config.properties
    - source: salt://app-server/{{ host['btm-config'] }}
    - user: root
    - group: tomcat7
    - mode: 644
    - template: jinja
{% endif %}
{% if 'btm-resources' in host %}
/etc/tomcat7/btm-resources.properties:
  file.managed:
    - name: /etc/tomcat7/btm-resources.properties
    - source: salt://app-server/{{ host['btm-resources'] }}
    - user: root
    - group: tomcat7
    - mode: 644
    - template: jinja
{% endif %}

#tomcat-option-for-btm:
#  file.blockreplace:
#    - name: /etc/default/tomcat7
#    - marker_start: "# BLOCK TOP : salt managed zone : local services : please do not edit"
#    - marker_end: "# BLOCK BOTTOM : end of salt managed zone --"
#    - content: 'JAVA_OPTS="$JAVA_OPTS -Dbtm.root=/var/lib/tomcat7 -Dbitronix.tm.configuration=/etc/tomcat7/btm-config.properties"'
#    - show_changes: True
#    - append_if_not_found: True

# server.pem should be obsolet when switching to nio https connector, replaced by .keystore
#/etc/tomcat7/server.pem:
#  file.managed:
#    - name: /etc/tomcat7/server.pem
#    - source: salt://app-server/certs/server.pem
#    - user: root
#    - group: tomcat7
#    - mode: 644

# server.crt should be obsolet when switching to nio https connector, replaced by .keystore
#/etc/tomcat7/server.crt:
#  file.managed:
#    - name: /etc/tomcat7/server.crt
#    - source: salt://app-server/certs/server-{{ host['networking']['hostname'] }}.crt
#    - user: root
#    - group: tomcat7
#    - mode: 644

# Used by nio https connector
/usr/share/tomcat7/got_ufinternal_net.full.p12:
  file.managed:
    - name: /usr/share/tomcat7/got_ufinternal_net.full.p12
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.full.p12
    - user: root
    - group: tomcat7
    - mode: 640

# Used by jmx
/usr/share/tomcat7/tomcat.keystore:
  file.managed:
    - name: /usr/share/tomcat7/tomcat.keystore
    - source: salt://app-server/keystores/server/tomcat.keystore
    - user: root
    - group: tomcat7
    - mode: 640

/usr/share/tomcat7/tomcat.truststore:
  file.managed:
    - name: /usr/share/tomcat7/tomcat.truststore
    - source: salt://app-server/keystores/server/tomcat.truststore
    - user: root
    - group: tomcat7
    - mode: 640

/etc/default/tomcat7:
  file.managed:
    - name: /etc/default/tomcat7
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/tomcat7-default
    - user: root
    - group: root
    - mode: 644
    - template: jinja

tomcat-extra-jars:
  file.recurse:
    - name: /usr/share/tomcat7/common
    - user: root
    - group: root
    - source: salt://app-server/tomcat-common

tomcat-extra-jars-remove:
  file.absent:
    - names:
      - /usr/share/tomcat7/common/postgresql-9.2-1002.jdbc4.jar
      - /usr/share/tomcat7/common/postgresql-9.4-1200.jdbc4.jar
      - /usr/share/tomcat7/common/postgresql-9.4-1200.jdbc41.jar

tomcat-manager-max-deploy-file-size1:
  file.replace:
    - name: /usr/share/tomcat7-admin/manager/WEB-INF/web.xml
    - pattern: '<max-file-size>52428800</max-file-size>'
    - repl: '<max-file-size>-1</max-file-size>'
    - backup: false
    - show_changes: true

tomcat-manager-max-deploy-file-size2:
  file.replace:
    - name: /usr/share/tomcat7-admin/manager/WEB-INF/web.xml
    - pattern: '<max-request-size>52428800</max-request-size>'
    - repl: '<max-request-size>-1</max-request-size>'
    - backup: false
    - show_changes: true

/var/webapp:
  file.directory:
    - name: /var/webapp
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/var/unifaun:
  file.directory:
    - name: /var/unifaun
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/var/bobapp:
  file.directory:
    - name: /var/bobapp
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/var/hitapp:
  file.directory:
    - name: /var/hitapp
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/usr/local/ufofs:
  file.directory:
    - name: /usr/local/ufofs
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/usr/local/ufofs/files:
  file.directory:
    - name: /usr/local/ufofs/files
    - user: tomcat7
    - group: tomcat7
    - mode: 770

/var/ufoedi:
  file.directory:
    - name: /var/ufoedi
    - user: tomcat7
    - group: tomcat7
    - mode: 770


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
    - source: salt://cron/bin/ufcleanup-webapp.sh
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
        service: tomcat7
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
        service: tomcat7
{% endif %}

{% if salt['file.directory_exists' ]('/var/lib/tomcat7/webapps/ROOT') %}
owner-/var/lib/tomcat7/webapps/ROOT:
  file.directory:
    - name: /var/lib/tomcat7/webapps/ROOT
    - user: tomcat7
    - group: tomcat7
    - recurse:
      - user
      - group
{% endif %}
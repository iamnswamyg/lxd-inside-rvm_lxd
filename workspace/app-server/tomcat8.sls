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

tomcat8:
  pkg:
    - installed

tomcat8-admin:
  pkg:
    - installed

tomcat-group:
  group.present:
    - name: uftomcat
    - gid: 3991
tomcat-user:
  user.present:
    - name: uftomcat
    - uid: 3991
    - gid: 3991
    - fullname: UF Tomcat User
    - groups:
      - adm
      - syslog
      - tomcat8

tomcat-umask:
  file.replace:
    - name: /usr/share/tomcat8/bin/catalina.sh
    - pattern: 'umask 0227'
    - repl: 'umask 0027' 
    - append_if_not_found: True

tomcat-service:
  service.running:
    - name: tomcat8
    - enable: True

wget:
  pkg:
    - installed

/etc/tomcat8/tomcat-users.xml:
  file.managed:
    - name: /etc/tomcat8/tomcat-users.xml
    - source: salt://app-server/tomcat-users.xml
    - user: root
    - group: tomcat8
    - mode: 640
    - watch_in:
      - service: tomcat-service

/etc/tomcat8/jmxremote.properties:
  file.managed:
    - name: /etc/tomcat8/jmxremote.properties
    - source: salt://app-server/jmxremote.properties
    - user: uftomcat
    - group: tomcat8
    - mode: 600
    - template: jinja
    - context:
        tomcat_config_path: /etc/tomcat8
    - watch_in:
      - service: tomcat-service

/etc/tomcat8/jmxremotessl.properties:
  file.managed:
    - name: /etc/tomcat8/jmxremotessl.properties
    - source: salt://app-server/jmxremotessl.properties
    - user: uftomcat
    - group: tomcat8
    - mode: 600
    - template: jinja
    - context:
        tomcat_user_home: /var/lib/tomcat8
    - watch_in:
      - service: tomcat-service

{% if 'tomcat-config-name' in host %}
/etc/tomcat8/server.xml:
  file.managed:
    - name: /etc/tomcat8/server.xml
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/server.xml
    - user: root
    - group: tomcat8
    - mode: 644
    - watch_in:
      - service: tomcat-service
    - template: jinja
{% endif %}

{% if 'tomcat-template-files' in host %}
{% set files = host['tomcat-template-files'] %}
{% for target in files %}
/etc/tomcat8/{{ target }}:
  file.managed:
    - name: /etc/tomcat8/{{ target }}
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat8
    - mode: 644
    - replace: false
    - watch_in:
      - service: tomcat-service
/etc/tomcat8/{{ target }}.template:
  file.managed:
    - name: /etc/tomcat8/{{ target }}.template
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/{{ target }}
    - user: root
    - group: tomcat8
    - mode: 644
{% endfor %}
{% endif %}
{% if 'btm-config' in host %}
/etc/tomcat8/btm-config.properties:
  file.managed:
    - name: /etc/tomcat8/btm-config.properties
    - source: salt://app-server/{{ host['btm-config'] }}
    - user: root
    - group: tomcat8
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat-service
{% endif %}
{% if 'btm-resources' in host %}
/etc/tomcat8/btm-resources.properties:
  file.managed:
    - name: /etc/tomcat8/btm-resources.properties
    - source: salt://app-server/{{ host['btm-resources'] }}
    - user: root
    - group: tomcat8
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat-service
{% endif %}

# Used by nio https connector
/var/lib/tomcat8/got_ufinternal_net.full.p12:
  file.managed:
    - name: /var/lib/tomcat8/got_ufinternal_net.full.p12
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.full.p12
    - user: root
    - group: tomcat8
    - mode: 640
    - watch_in:
      - service: tomcat-service

# Used by jmx
/var/lib/tomcat8/tomcat.keystore:
  file.managed:
    - name: /var/lib/tomcat8/tomcat.keystore
    - source: salt://app-server/keystores/server/tomcat.keystore
    - user: root
    - group: tomcat8
    - mode: 640
    - watch_in:
      - service: tomcat-service

/var/lib/tomcat8/tomcat.truststore:
  file.managed:
    - name: /var/lib/tomcat8/tomcat.truststore
    - source: salt://app-server/keystores/server/tomcat.truststore
    - user: root
    - group: tomcat8
    - mode: 640
    - watch_in:
      - service: tomcat-service
    - watch_in:
      - service: tomcat-service

/etc/default/tomcat8:
  file.managed:
    - name: /etc/default/tomcat8
    - source: salt://app-server/lxc-instances/{{ host['tomcat-config-name'] }}/tomcat8-default
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: tomcat-service

tomcat-extra-jars:
  file.recurse:
    - name: /usr/share/tomcat8/lib
    - user: root
    - group: root
    - source: salt://app-server/tomcat8-lib
    - watch_in:
      - service: tomcat-service

tomcat-extra-jars-jta:
  file.recurse:
    - name: /usr/share/tomcat8/lib
    - user: root
    - group: root
    - watch_in:
      - service: tomcat-service
{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
    - source: salt://app-server/tomcat8-lib-narayana
{% else %}
    - source: salt://app-server/tomcat8-lib-btm
{% endif %}

tomcat-extra-jars-remove:
  file.absent:
    - names:
      - /usr/share/tomcat8/lib/postgresql-42.2.6.jar
      - /usr/share/tomcat8/lib/geronimo-jta_1.0.1B_spec-1.0.1.jar
{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
      - /usr/share/tomcat8/lib/btm-3.0.0-SNAPSHOT-2014-08-22.jar
      - /usr/share/tomcat8/lib/btm-tomcat55-lifecycle-3.0.0-SNAPSHOT-2014-08-22.jar
{% else %}
      - /usr/share/tomcat8/lib/tomcat-narayana-jta-5.9.0.Final.jar
      - /usr/share/tomcat8/lib/log4j-1.2.14.jar
      - /usr/share/tomcat8/lib/commons-pool2-2.10.0.jar
      - /usr/share/tomcat8/lib/commons-logging-1.2.jar
      - /usr/share/tomcat8/lib/commons-dbcp2-2.8.0.jar
{% endif %}

tomcat-manager-max-deploy-file-size1:
  file.replace:
    - name: /usr/share/tomcat8-admin/manager/WEB-INF/web.xml
    - pattern: '<max-file-size>52428800</max-file-size>'
    - repl: '<max-file-size>-1</max-file-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat-service

tomcat-manager-max-deploy-file-size2:
  file.replace:
    - name: /usr/share/tomcat8-admin/manager/WEB-INF/web.xml
    - pattern: '<max-request-size>52428800</max-request-size>'
    - repl: '<max-request-size>-1</max-request-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat-service

/var/webapp:
  file.directory:
    - name: /var/webapp
    - user: uftomcat
    - group: tomcat8
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/unifaun:
  file.directory:
    - name: /var/unifaun
    - user: uftomcat
    - group: tomcat8
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/bobapp:
  file.directory:
    - name: /var/bobapp
    - user: uftomcat
    - group: tomcat8
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/hitapp:
  file.directory:
    - name: /var/hitapp
    - user: uftomcat
    - group: tomcat8
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/usr/local/ufofs:
  file.directory:
    - name: /usr/local/ufofs
    - user: uftomcat
    - group: tomcat8
    - mode: 770
    - recurse:
      - user
      - group
      - mode

/var/ufoedi:
  file.directory:
    - name: /var/ufoedi
    - user: uftomcat
    - group: tomcat8
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
    - source: salt://cron/bin/ufcleanup-webapp-tomcat8.sh
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
        service: tomcat8
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
        service: tomcat8
{% endif %}

# will be set in server/init.sls for ubuntu 18.04
#sv_SE_locale:
#  locale.present:
#    - name: sv_SE.utf8

/var/lib/tomcat8/webapps:
  file.directory:
    - user: uftomcat
    - recurse:
      - user

{% if salt['file.directory_exists' ]('/var/cache/tomcat8') %}
/var/cache/tomcat8:
  file.directory:
    - user: uftomcat
    - recurse:
      - user
{% endif %}

{% if salt['file.directory_exists' ]('/var/log/tomcat8') %}
/var/log/tomcat8:
  file.directory:
    - user: uftomcat
    - recurse:
      - user
{% endif %}

wait-for-tomcatmanager:
  tomcat.wait:
    - timeout: 300
    - require:
      - service: tomcat-service

{% if salt['file.directory_exists' ]('/var/lib/tomcat8/webapps/ROOT') %}
owner-/var/lib/tomcat8/webapps/ROOT:
  file.directory:
    - name: /var/lib/tomcat8/webapps/ROOT
    - user: uftomcat
    - group: tomcat8
    - recurse:
      - user
      - group
    - require:
      - pkg: tomcat8
{% endif %}

{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
/var/lib/tomcat8/ObjectStore:
  file.symlink:
    - name: /var/lib/tomcat8/ObjectStore
    - target: work/Narayana/ObjectStore
    - user: tomcat8
    - group: uftomcat
{% endif %}
    
{%- set tomcatversion = pillar['ufconfig']['tomcat-versions']['version'] %}
{%- set majorversion = pillar['ufconfig']['tomcat-versions']['majorversion'] %}
{% import_yaml tpldir ~ "/workers.yaml" as workersData %}
{%- set host = pillar['ufconfig']['hosts'][grains.id] %}
{%- set network = pillar['ufconfig']['networks'][host['networking']['network']] %}
{% set site = network['site'] %}

{# SECTION 1: DEPENDENCIES / BOOTSTRAP / CONFIG PUSHING #}
accepted-mscorefonts-eula:
  debconf.set:
    - name: ttf-mscorefonts-installer
    - data:
        'msttcorefonts/accepted-mscorefonts-eula': {'type': 'boolean', 'value': 'true'}

tomcat-group:
  group.present:
    - name: tomcat
    - gid: 3991

tomcat-user:
  user.present:
    - name: tomcat
    - uid: 3991
    - gid: 3991
    - usergroup: True
    - allow_uid_change: True
    - allow_gid_change: True
    - fullname: Tomcat User
    - home: /opt/tomcat
    - groups:
      - adm
      - syslog
      - tomcat

tomcat_deps:
  pkg.installed:
    - pkgs:
      - ttf-mscorefonts-installer
      - libtcnative-1
      - wget

{#
  Example Tomcat download URLs:
  https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.64/bin/
  https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.64/bin/apache-tomcat-9.0.64.tar.gz
#}

tomcat-download:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}.tar.gz
    - source: https://archive.apache.org/dist/tomcat/tomcat-{{ majorversion }}/v{{ tomcatversion }}/bin/apache-tomcat-{{ tomcatversion }}.tar.gz
    - source_hash: https://archive.apache.org/dist/tomcat/tomcat-{{ majorversion }}/v{{ tomcatversion }}/bin/apache-tomcat-{{ tomcatversion }}.tar.gz.sha512

tomcat-unpack:
  archive.extracted:
    - name: /opt
    - source: /opt/apache-tomcat-{{ tomcatversion }}.tar.gz
    - if_missing: /opt/apache-tomcat-{{ tomcatversion }}

tomcat-symlink:
  file.symlink:
    - name:  /opt/tomcat
    - target: /opt/apache-tomcat-{{ tomcatversion }}
    - user: tomcat
    - group: tomcat
    - force: True

tomcat-var-log-symlink:
  file.symlink:
    - name:  /var/log/tomcat
    - target: /opt/apache-tomcat-{{ tomcatversion }}/logs
    - user: tomcat
    - group: tomcat
    - force: True

# From catalina.sh:
# #   UMASK           (Optional) Override Tomcat's default UMASK of 0027
# Meaning:
# The default is already 0027, no need to pattern match for anything else:
# and if we want to be really sure, we should set env $UMASK, not repl.
#tomcat-catalinash-umask:
#  file.replace:
#    - name: /opt/apache-tomcat-{{ tomcatversion }}/bin/catalina.sh
#    - pattern: 'umask 0227'
#    - repl: 'umask 0027' 
#    - append_if_not_found: True

/etc/systemd/system/tomcat.service:
  file.managed:
    - source: salt://app-server/tomcat-tar/tomcat.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        tomcatversion: {{ tomcatversion }}
  service.enabled:
    - name: tomcat
  module.run: 
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/tomcat.service

# we do not set /opt/tomcat perms here when pushing files, these will be corrected later 

tomcat-users.xml:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/tomcat-users.xml
    - source: salt://app-server/tomcat-users.xml
    - watch_in:
      - service: tomcat-service

tomcat-conf-context:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/context.xml
    - source: salt://app-server/tomcat-tar/conf-context.xml
    - watch_in:
      - service: tomcat-service

tomcat-manager-context:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/webapps/manager/META-INF/context.xml
    - source: salt://app-server/tomcat-tar/manager-context.xml
    - template: jinja
    - context:
        site: {{ site }}
    - watch_in:
      - service: tomcat-service

{% if 'tomcat-config-name' in host %}
server.xml:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/server.xml
    - source: salt://app-server/lxc-instances/tomcat-tar-config/{{ host['tomcat-config-name'] }}/server.xml
    - watch_in:
      - service: tomcat-service
    - template: jinja
{% endif %}

{% if 'tomcat-template-files' in host %}
{% set files = host['tomcat-template-files'] %}
{% for target in files %}
conf/{{ target }}:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/{{ target }}
    - source: salt://app-server/lxc-instances/tomcat-tar-config/{{ host['tomcat-config-name'] }}/{{ target }}
    - replace: false
    - watch_in:
      - service: tomcat-service
conf/{{ target }}.template:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/{{ target }}.template
    - source: salt://app-server/lxc-instances/tomcat-tar-config/{{ host['tomcat-config-name'] }}/{{ target }}
{% endfor %}
{% endif %}

{# no longer used? I guess narayana replaces btm? /linusa #}
{% if 'btm-config' in host %}
conf/btm-config.properties:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/btm-config.properties
    - source: salt://app-server/{{ host['btm-config'] }}
    - template: jinja
    - watch_in:
      - service: tomcat-service
{% endif %}
{% if 'btm-resources' in host %}
conf/btm-resources.properties:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/btm-resources.properties
    - source: salt://app-server/{{ host['btm-resources'] }}
    - template: jinja
    - watch_in:
      - service: tomcat-service
{% endif %}

# Used by nio https connector
got_ufinternal_net.full.p12:
  file.managed:
    - name: /opt/tomcat/got_ufinternal_net.full.p12
    - source: salt://ssl-certs/got.ufinternal.net/got_ufinternal_net.full.p12
    - watch_in:
      - service: tomcat-service

# Used by jmx
tomcat.keystore:
  file.managed:
    - name: /opt/tomcat/tomcat.keystore
    - source: salt://app-server/keystores/server/tomcat.keystore
    - watch_in:
      - service: tomcat-service

tomcat.truststore:
  file.managed:
    - name: /opt/tomcat/tomcat.truststore
    - source: salt://app-server/keystores/server/tomcat.truststore
    - watch_in:
      - service: tomcat-service

tomcat-extra-jars:
  file.recurse:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/lib
    - source: salt://app-server/tomcat9-lib
    - watch_in:
      - service: tomcat-service

tomcat-extra-jars-jta:
  file.recurse:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/lib
    - watch_in:
      - service: tomcat-service
    - source: salt://app-server/tomcat9-lib-narayana

tomcat-manager-webxml-max-deploy-file-size1:
  file.replace:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/webapps/manager/WEB-INF/web.xml
    - pattern: '<max-file-size>52428800</max-file-size>'
    - repl: '<max-file-size>-1</max-file-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat-service

tomcat-manager-webxml-max-deploy-file-size2:
  file.replace:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/webapps/manager/WEB-INF/web.xml
    - pattern: '<max-request-size>52428800</max-request-size>'
    - repl: '<max-request-size>-1</max-request-size>'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat-service

{# Push root-owned files #}

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
#   Uses incorrect paths! Forked into tomcat-tar
#    - source: salt://cron/bin/ufcleanup-webapp-tomcat9.sh
    - source: salt://app-server/tomcat-tar/ufcleanup-webapp-tomcat.sh
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




{% if network['site'] == 'aws1' %}
/usr/local/bin/ufrestart-webapp.sh:
  file.managed:
    - name: /usr/local/bin/ufrestart-webapp.sh
    - source: salt://cron/bin/ufrestart-webapp-simple.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        service: tomcat
{% endif %}

{% if 'tomcat-dbconfig-name' in host and network['site'] == 'aws1' %}
globalnamingresources-for-test-env:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/globalnamingresources.txt
    - source: salt://app-server/lxc-instances/tomcat-tar-config/{{ host['tomcat-config-name'] }}/globalnamingresources_{{ host['tomcat-dbconfig-name'] }}.txt
    - user: tomcat
    - mode: 440
    - watch_in:
      - service: tomcat-service
{% endif %}

{% if network['site'] == 'ufcolo1' or network['site'] == 'ufcolo2' %}
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
        service: tomcat

globalnamingresources-FOR-PROD-ENV:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/globalnamingresources.txt
    - source: salt://app-server/lxc-instances/tomcat-tar-config/{{ host['tomcat-config-name'] }}/globalnamingresources_prod.txt
    - user: tomcat
    - mode: 440
    - watch_in:
      - service: tomcat-service

{#-
  Also in prod:
  tomcat-tar nodes should, unconditionally, have their own context.xml for 'ResourceLink' objects,
  that should override config bundled with the application in /META-INF/context.xml
  NOTE: this file by itself does nothing, it depends on symlinks created by ufdeploy over salt
  See also: https://tomcat.apache.org/tomcat-9.0-doc/config/context.html#Defining_a_context
#}
/opt/tomcat/override-context.xml:
  file.managed:
    - source: salt://app-server/tomcat-tar/override-context.xml
    - user: root
    - group: tomcat
    - mode: 440
{% endif %}

{# This file should not exist as it's created by the 'old' way of pushing globalnamingresources #}
globalnamingresources-template-gone:
  file.absent:
    - names:
      - /opt/apache-tomcat-{{ tomcatversion }}/conf/globalnamingresources.txt.template

tomcat-remove-extra-jars:
  file.absent:
    - names:
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/postgresql-42.2.6.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/geronimo-jta_1.0.1B_spec-1.0.1.jar
{% if 'tomcat-use-narayana' in host and host['tomcat-use-narayana'] == True %}
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/btm-3.0.0-SNAPSHOT-2014-08-22.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/btm-tomcat55-lifecycle-3.0.0-SNAPSHOT-2014-08-22.jar
{% else %}
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/tomcat-narayana-jta-5.9.0.Final.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/log4j-1.2.14.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/commons-pool2-2.10.0.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/commons-logging-1.2.jar
      - /opt/apache-tomcat-{{ tomcatversion }}/lib/commons-dbcp2-2.8.0.jar
{% endif %}

{# SECTION 2: SET/ENSURE PERMISSIONS #}

tomcat-jars-libfolder:
  file.directory:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/lib
    - user: root
    - group: tomcat
    - file_mode: 640
    - dir_mode: 750
    - recurse:
      - user
      - group
      - mode
    - watch_in:
      - service: tomcat-service

/var/webapp:
  file.directory:
    - name: /var/webapp
    - user: root
    - group: tomcat
    - mode: 770

/var/unifaun:
  file.directory:
    - name: /var/unifaun
    - user: root
    - group: tomcat
    - mode: 770

/var/bobapp:
  file.directory:
    - name: /var/bobapp
    - user: root
    - group: tomcat
    - mode: 770

/var/hitapp:
  file.directory:
    - name: /var/hitapp
    - user: root
    - group: tomcat
    - mode: 770

/usr/local/ufofs:
  file.directory:
    - name: /usr/local/ufofs
    - user: root
    - group: tomcat
    - mode: 770

/var/ufoedi:
  file.directory:
    - name: /var/ufoedi
    - user: root
    - group: tomcat
    - mode: 770

/opt/tomcat/webapps:
  file.directory:
    - user: tomcat
    - recurse:
      - user

/opt/tomcat/logs:
  file.directory:
    - user: tomcat
    - recurse:
      - user

{#
  NOTE: This shouldn't be used for anything. Still, it
  doesn't hurt that it exists and has reasonable perms.
  
  Make sure /var/log/tomcat exists and has user:tomcat
#}

/var/log/tomcat:
  file.directory:
    - user: tomcat
    - recurse:
      - user

/opt/tomcat/temp:
  file.directory:
    - user: tomcat
    - recurse:
      - user

{% if salt['file.directory_exists' ]('/opt/tomcat/webapps/ROOT') %}
webapps/ROOT-ownership:
  file.directory:
    - name: /opt/tomcat/webapps/ROOT
    - user: tomcat
    - group: tomcat
    - recurse:
      - user
      - group
{% endif %}

remove-tomcat-packages:
  pkg.removed:
    - pkgs:
      - tomcat7
      - tomcat8
      - tomcat9

remove-initd-service-files-for-older-tomcat-versions:
  file.absent:
    - names:
      - /etc/init.d/tomcat9
      - /etc/init.d/tomcat8
      - /etc/init.d/tomcat7

{# These webapps are included by default, we probably don't want them #}

delete-webapps-docs:
  file.absent:
    - name: /opt/tomcat/webapps/docs

delete-webapps-examples:
  file.absent:
    - name: /opt/tomcat/webapps/examples

{#
  Ensure tomcat group applies to the entire directory
#}

{# NOTE: This will change ownership for 'override-context.xml' symlinks -- it's ok! #}
set-tomcat-dir-group:
  file.directory:
    - name: /opt/apache-tomcat-{{ tomcatversion }}
    - group: tomcat
    - recurse:
      - group

let-tomcat-write-work-dir:
  file.directory:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/work
    - user: tomcat
    - group: tomcat
    - dir_mode: 770
    - recurse:
      - user

{# NOTE: This will change ownership for 'override-context.xml' symlinks -- it's ok! #}
tomcat-user-for-conf-dir:
  file.directory:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf
    - user: tomcat
    - recurse:
      - user

let-tomcat-execute-bin-files:
  file.directory:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/bin
    - user: root
    - group: tomcat
    - file_mode: 650
    - dir_mode: 750
    - recurse:
      - user
      - group
      - mode

{#
  special case for the tomcat conf folder:
  some files here need to be very restrictive (400)
#}

jmxremote.properties:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/jmxremote.properties
    - source: salt://app-server/jmxremote.properties
    - user: tomcat
    - group: tomcat
    - mode: 400
    - template: jinja
    - context:
        tomcat_config_path: /opt/apache-tomcat-{{ tomcatversion }}/conf
    - watch_in:
      - service: tomcat-service

jmxremotessl.properties:
  file.managed:
    - name: /opt/apache-tomcat-{{ tomcatversion }}/conf/jmxremotessl.properties
    - source: salt://app-server/jmxremotessl.properties
    - user: tomcat
    - group: tomcat
    - mode: 400
    - template: jinja
    - context:
        tomcat_user_home: /opt/tomcat
    - watch_in:
      - service: tomcat-service

{#
  init_delay waits N seconds after the service has gone active
  before completing the state.

  this is used instead of tomcat.wait due to it seemingly not
  actually waiting and causing errors. presumably this should
  work just as well, and seems like a more general, non-tomcat
  specific solution.

  NOTE: if deploy failures happen, you may need to increase it.
#}

tomcat-service:
  service.running:
    - name: tomcat
    - enable: True
    - init_delay: 15

{#
  hardcoded war-deployments taken from 'wars' and 'wars-std'
  this avoids the necessity of setting 'app.server.wars' etc.
  for the host in question: the assumption is that if it's
  going to have tomcat it should have these wars which seem
  to be used pretty much everywhere. for example:
  all test3-* containers have both.
#}

{% if 'tomcat-webapps' in host %}
{% set webapps = host['tomcat-webapps'] %}
{% for context in webapps %}
{% set app = host['tomcat-webapps'][context] %}
{% set webapp = pillar['ufconfig']['applications'][app] %}
tomcat-war-{{ context }}:
  tomcat.war_deployed:
    - name: /{{ context }}
    - war: salt://app-server/wars/auto-forwarder-1.0.war
    - require:
      - service: tomcat-service
{% if 'extra-auto-forwarders' in webapp %}
{% for contextSufix in webapp['extra-auto-forwarders'] %}
tomcat-war-{{ context }}-{{ contextSufix }}:
  tomcat.war_deployed:
    - name: /{{ context }}-{{ contextSufix }}
    - war: salt://app-server/wars/auto-forwarder-1.0.war
    - require:
      - service: tomcat-service
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}

tomcat-war-switchover:
  tomcat.war_deployed:
    - name: /switchover
    - war: salt://app-server/wars/switchover-1.0.war
    - require:
      - service: tomcat-service

tomcat-war-fwdmanager:
  tomcat.war_deployed:
    - name: /fwdmanager
    - war: salt://app-server/wars/fwdmanager-1.0.war
    - require:
      - service: tomcat-service

tomcat-war-ufoweb-root:
  tomcat.war_deployed:
    - name: /
    - war: salt://app-server/wars/root-1.0.war
    - require:
      - service: tomcat-service
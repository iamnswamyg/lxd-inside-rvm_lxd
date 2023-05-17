{% set host = pillar['ufconfig']['hosts'][grains.id] -%}
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
      - tomcat: wait-for-tomcatmanager
{% if 'extra-auto-forwarders' in webapp %}
{% for contextSufix in webapp['extra-auto-forwarders'] %}
tomcat-war-{{ context }}-{{ contextSufix }}:
  tomcat.war_deployed:
    - name: /{{ context }}-{{ contextSufix }}
    - war: salt://app-server/wars/auto-forwarder-1.0.war
    - require:
      - tomcat: wait-for-tomcatmanager
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}

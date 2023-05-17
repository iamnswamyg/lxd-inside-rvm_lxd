
tomcat-war-switchover:
  tomcat.war_deployed:
    - name: /switchover
    - war: salt://app-server/wars/switchover-1.0.war
    - require:
      - tomcat: wait-for-tomcatmanager

tomcat-war-fwdmanager:
  tomcat.war_deployed:
    - name: /fwdmanager
    - war: salt://app-server/wars/fwdmanager-1.0.war
    - require:
      - tomcat: wait-for-tomcatmanager

tomcat-war-ufoweb-root:
  tomcat.war_deployed:
    - name: /
    - war: salt://app-server/wars/root-1.0.war
    - require:
      - tomcat: wait-for-tomcatmanager

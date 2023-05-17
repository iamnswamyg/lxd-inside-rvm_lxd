/usr/share/tomcat7/bin-clean:
  file.directory:
    - name: /usr/share/tomcat7/bin
    - user: root
    - group: root
    - clean: True
    - file_mode: 755
    - dir_mode: 755
    - onlyif:
      - test -L /usr/share/tomcat7/bin/tomcat-juli.jar

/usr/share/tomcat7/bin:
  file.recurse:
    - name: /usr/share/tomcat7/bin
    - user: root
    - group: root
    - source: salt://app-server/tomcat7-upd/bin
    - file_mode: 755

/usr/share/tomcat7/lib-clean:
  file.directory:
    - name: /usr/share/tomcat7/lib
    - user: root
    - group: root
    - clean: True
    - file_mode: 755
    - dir_mode: 755
    - onlyif:
      - test -L /usr/share/tomcat7/lib/annotations-api.jar

/usr/share/tomcat7/lib:
  file.recurse:
    - name: /usr/share/tomcat7/lib
    - user: root
    - group: root
    - source: salt://app-server/tomcat7-upd/lib
    - file_mode: 755

/usr/share/tomcat7-admin/manager:
  file.recurse:
    - name: /usr/share/tomcat7-admin/manager
    - user: root
    - group: root
    - source: salt://app-server/tomcat7-upd/manager
    - file_mode: 644

/usr/share/tomcat7-admin/host-manager:
  file.recurse:
    - name: /usr/share/tomcat7-admin/host-manager
    - user: root
    - group: root
    - source: salt://app-server/tomcat7-upd/host-manager
    - file_mode: 644

tomcat-group:
  group.present:
    - name: tomcat
    - gid: 3991
    - members:
      - tomcat7

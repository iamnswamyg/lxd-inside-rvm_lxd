# Fix for tomcat7 to work with java 11
# java.endorsed.dirs
/usr/share/tomcat7/bin/setclasspath.sh:
  file.replace:
    - name: /usr/share/tomcat7/bin/setclasspath.sh
    - pattern: {{ 'JAVA_ENDORSED_DIRS="$CATALINA_HOME"/endorsed' | regex_escape }}
    - repl: 'JAVA_ENDORSED_DIRS=""'
    - backup: false
    - show_changes: true
    - watch_in:
      - service: tomcat7
    - require:
      - pkg: tomcat7

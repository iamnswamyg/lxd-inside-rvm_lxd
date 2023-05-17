{% set host = pillar['ufconfig']['hosts'][grains.id] -%}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}
export CLASSPATH=`find /usr/share/tomcat9/lib/ -type f -regex '.*/commons-\(dbcp\|pool\|dbcp2\|pool2\|logging\)-.*\.jar' -o -regex '.*/tomcat-narayana-jta.*\.jar' -o -regex '.*/geronimo-jta.*\.jar' | tr '\n' ':'`
export CATALINA_OPTS="$CATALINA_OPTS \
-Djava.awt.headless=true \
-Xmx512m \
-Xms128m \
-XX:MaxMetaspaceSize=512M \
-Xlog:gc*:file=/var/log/tomcat9/gc.log:time:filecount=10,filesize=102400 \
-XX:+UseG1GC \
-Dcom.sun.management.config.file=/etc/tomcat9/jmxremote.properties \
-Duf.tomcat.server.name={{ host['tomcat-name'] }} \
-DCoreEnvironmentBean.nodeIdentifier={{ host['tomcat-name'] }}
-Duf.tomcat.log.dir=/var/log/tomcat9 \
-Duf.tomcat.sticky.route={{ host['tomcat-route'] }} \
-Duf.site={{ network['site'] }} \
 "
export LOGFILE_COMPRESS=0

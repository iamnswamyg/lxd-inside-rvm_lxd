{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}

#  pkgrepo.managed:
#    - humanname: WEB UPD8 Repository
#    - name: deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main
#    - gpgcheck: 1
#    - keyid: EEA14886
#    - keyserver: keyserver.ubuntu.com
#    - enabled: 1
#    - require_in:
#      - pkg: openjdk-8-jre-headless

#software-properties-common:
#  pkg:
#    - installed
    
#openjdk-r/ppa:
#  pkgrepo.managed:
#    - humanname: PPA for OpenJDK uploads (restricted)
#    - ppa: openjdk-r/ppa
#    - require_in:
#      - pkg: openjdk-8-jre-headless
#    - requires:
#      - pkg: software-properties-common
    
openjdk-r/ppa:
  pkgrepo.managed:
    - humanname: PPA for OpenJDK uploads (restricted)
    - name: deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
    - key_url: salt://app-server/openjdk-r.ppa.key
    - gpgcheck: 1
    - refresh_db: True
    - require_in:
      - pkg: openjdk-8-jre-headless

openjdk-8-jre-headless:
  pkg:
    - installed
    - require_in:
      - tomcat7
      - tomcat7-admin

openjdk-8-jre-headless_default:
  alternatives.set:
    - name: java
    - path: /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java


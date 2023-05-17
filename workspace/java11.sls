openjdk-r/ppa:
  pkgrepo.managed:
    - humanname: PPA for OpenJDK uploads (restricted)
{% if grains['osfinger'] != 'Ubuntu-18.04' %}
    - name: deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
{% else %}
    - name: deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main
{% endif %}
    - key_url: salt://app-server/openjdk-r.ppa.key
    - gpgcheck: 1
    - refresh_db: True
    - require_in:
      - pkg: openjdk-11-jre-headless

openjdk-11-jre-headless:
  pkg:
    - installed
    - require_in:
      - tomcat7
      - tomcat7-admin

{% if grains['osfinger'] != 'Ubuntu-18.04' %}
openjdk-11-jre-headless_default:
  alternatives.set:
    - name: java
    - path: /usr/lib/jvm/java-11-openjdk-amd64/bin/java
{% endif %}
    
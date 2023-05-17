{% import_yaml tpldir ~ "/web-servers.yaml" as webServerData %}
{% set host = pillar['ufconfig']['hosts'][grains.id] %}
{% set network = pillar['ufconfig']['networks'][host['networking']['network']] %}
{% set hosts = pillar['ufconfig']['hosts'] -%}

sendemail:
  pkg:
    - installed

wget:
  pkg:
    - installed

/usr/local/bin/ufmaster-switch.sh:
  file.managed:
    - name: /usr/local/bin/ufmaster-switch.sh
    - source: salt://ufdeploy/bin/ufmaster-switch.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja

/usr/local/bin/ufswitchover-notify-msteams.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-notify-msteams.sh
    - source: salt://ufdeploy/bin/ufswitchover-notify-msteams.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufdeploy.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufdeploy.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja

/usr/local/bin/ufdeploy-dns.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-dns.sh
    - source: salt://ufdeploy/webapp/ufdeploy/ufdeploy-dns.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/webapp/ufenv:
  file.recurse:
    - name: /usr/local/bin
    - user: root
    - group: root
    - source: salt://ufdeploy/webapp/ufenv
    - file_mode: 700
    - template: jinja
    - context:
        data: {{ webServerData | json }}

{%- for x in hosts|sort %}
{%- set i = hosts[x] %}
{%- if 'hidden' not in i or not i['hidden'] == True %}
{%- if 'absent' not in i or not i['absent'] == True %}
{%- set hostname = i['networking']['hostname'] %}

{%- if 'ufoffice-test1' in hostname or 'ufoffice-test3' in hostname %}
{%- if i['container'] is defined %}
{%- set target = i['container']['simple-name'] %}
/usr/local/bin/webapp/ufenv/ufenv-ufoweb-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-ufoweb-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-ufoweb-devtest.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/webapp/ufenv/ufenv-hitweb-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-hitweb-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-hitweb-devtest.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/webapp/ufenv/ufenv-ufofs-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-ufofs-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-ufofs-devtest.sh
    - user: root
    - group: root
    - mode: 700
{%- endif %}
{%- endif %}

# fix for aws

{%- if 'aws1-test1-' in hostname %}
{%- set target = i['simple-name'] %}
/usr/local/bin/webapp/ufenv/ufenv-ufoweb-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-ufoweb-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-ufoweb-devtest.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/webapp/ufenv/ufenv-hitweb-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-hitweb-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-hitweb-devtest.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/webapp/ufenv/ufenv-ufofs-devtest-{{ target }}.sh:
  file.symlink:
    - name: /usr/local/bin/ufenv-ufofs-devtest-{{ target }}.sh
    - target: /usr/local/bin/ufenvbase-ufofs-devtest.sh
    - user: root
    - group: root
    - mode: 700
{%- endif %}

# end of aws fix

{%- endif %}
{%- endif %}
{% endfor %}





/usr/local/bin/ee/ufenv:
  file.recurse:
    - name: /usr/local/bin
    - user: root
    - group: root
    - source: salt://ufdeploy/ee/ufenv
    - file_mode: 700
    - template: jinja


/usr/local/bin/ufwarmup.sh:
  file.managed:
    - name: /usr/local/bin/ufwarmup.sh
    - source: salt://ufdeploy/webapp/misc/ufwarmup.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja

/usr/local/bin/ufdeploy-ee.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-ee.sh
    - source: salt://ufdeploy/ee/ufdeploy/ufdeploy-ee.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufactivate-app.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-app.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-app.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja

/usr/local/bin/ufactivate-ee.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-ee.sh
    - source: salt://ufdeploy/ee/ufactivate/ufactivate-ee.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufactivate-site.sh:
  file.managed:
    - name: /usr/local/bin/ufactivate-site.sh
    - source: salt://ufdeploy/webapp/ufactivate/ufactivate-site.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
        webServers: {{ webServerData['servers'] | unique | sort | json }}


/usr/local/bin/ufswitchover.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufswitchover-wrapper.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-wrapper.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-wrapper.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufswitchover-ufoweb-prod-ufo.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-ufoweb-prod-ufo.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root

/usr/local/bin/ufswitchover-ufoweb-dbmig-ufo.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-ufoweb-dbmig-test.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root

/usr/local/bin/ufswitchover-ufofs-prod-ufofs.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-ufofs-prod-ufofs.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root

/usr/local/bin/ufswitchover-bobweb-prod-bob.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-bobweb-prod-bob.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root

/usr/local/bin/ufswitchover-hitweb-prod-hit.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-hitweb-prod-hit.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root
    
/usr/local/bin/ufswitchover-ufoee-prod-ee.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-ufoee-prod-ee.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root
    
/usr/local/bin/ufswitchover-hitee-prod-ee.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-hitee-prod-ee.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root
    
/usr/local/bin/ufswitchover-hitee-test-ee.sh:
  file.symlink:
    - name: /usr/local/bin/ufswitchover-hitee-test-ee.sh
    - target: /usr/local/bin/ufswitchover-wrapper.sh
    - user: root
    - group: root

/usr/local/bin/ufswitchover-ufoee.sh:
  file.absent:
    - name: /usr/local/bin/ufswitchover-ufoee.sh

/usr/local/bin/ufswitchover-hitee.sh:
  file.absent:
    - name: /usr/local/bin/ufswitchover-hitee.sh

/usr/local/bin/ufswitchover-pgsql-status.sh:
  file.managed:
    - name: /usr/local/bin/ufswitchover-pgsql-status.sh
    - source: salt://ufdeploy/webapp/ufswitchover/ufswitchover-pgsql-status.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufapp-list.sh:
  file.managed:
    - name: /usr/local/bin/ufapp-list.sh
    - source: salt://ufdeploy/webapp/ufapp/ufapp-list.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufapp-undeploy.sh:
  file.managed:
    - name: /usr/local/bin/ufapp-undeploy.sh
    - source: salt://ufdeploy/webapp/ufapp/ufapp-undeploy.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufee-list.sh:
  file.managed:
    - name: /usr/local/bin/ufee-list.sh
    - source: salt://ufdeploy/ee/ufee/ufee-list.sh
    - user: root
    - group: root
    - mode: 700
    
/usr/local/bin/ufee-undeploy.sh:
  file.managed:
    - name: /usr/local/bin/ufee-undeploy.sh
    - source: salt://ufdeploy/ee/ufee/ufee-undeploy.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/ufee-status.sh:
  file.managed:
    - name: /usr/local/bin/ufee-status.sh
    - source: salt://ufdeploy/ee/ufee/ufee-status.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/uflist-ufoee-prod-ee.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-ufoee-prod-ee.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
    
/usr/local/bin/uflist-ufoee-postitest-extern.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-ufoee-postitest-extern.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
    
/usr/local/bin/uflist-ufoee-potest-extern.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-ufoee-potest-extern.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
    
/usr/local/bin/uflist-ufoee-uotest-extern.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-ufoee-uotest-extern.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
    
/usr/local/bin/uflist-ufoee-bobtest-extern.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-ufoee-bobtest-extern.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
    
/usr/local/bin/uflist-hitee-prod-ee.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-hitee-prod-ee.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root
   
/usr/local/bin/uflist-hitee-test-ee.sh:
  file.symlink:
    - name: /usr/local/bin/uflist-hitee-test-ee.sh
    - target: /usr/local/bin/ufee-list.sh
    - user: root
    - group: root

/usr/local/bin/ufnotify-slack.sh:
  file.absent:
    - name: /usr/local/bin/ufnotify-slack.sh

/usr/local/bin/ufnotify-msteams.sh:
  file.managed:
    - name: /usr/local/bin/ufnotify-msteams.sh
    - source: salt://ufdeploy/webapp/misc/ufnotify-msteams.sh
    - user: root
    - group: root
    - mode: 700

/usr/local/bin/uftest-autdeploy:
  file.recurse:
    - name: /usr/local/bin
    - user: root
    - group: root
    - source: salt://ufdeploy/autodeploy
    - file_mode: 700
    - template: jinja

/usr/local/bin/ufcleanup-ufdist.sh:
  file.managed:
    - name: /usr/local/bin/ufcleanup-ufdist.sh
    - source: salt://cron/bin/ufcleanup-ufdist.sh
    - user: root
    - group: root
    - mode: 700

/etc/cron.d/ufcleanup-ufdist:
  file.managed:
    - name: /etc/cron.d/ufcleanup-ufdist
    - source: salt://cron/cron.d/ufcleanup-ufdist
    - user: root
    - group: root
    - mode: 644

/root/ufdist:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755

jenkins-deploy:
  user.present:
    - fullname: Jenkins Deploy
    - shell: /bin/bash
    - home: /home/jenkins-deploy
    - uid: 3993
  ssh_auth:
    - present
    - user: jenkins-deploy
    - config: /etc/ssh/auth/jenkins-deploy
    - source: salt://ufdeploy/ufdeploy-jenkins/ufdeploy-jenkins.id_rsa.pub
    - require:
      - user: jenkins-deploy

/usr/local/bin/ufdeploy-jenkins.sh:
  file.managed:
    - name: /usr/local/bin/ufdeploy-jenkins.sh
    - source: salt://ufdeploy/ufdeploy-jenkins/ufdeploy-jenkins.sh
    - user: root
    - group: root
    - mode: 700

/etc/sudoers.d/98-ufdeploy-jenkins:
  file.managed:
    - name: /etc/sudoers.d/98-ufdeploy-jenkins
    - source: salt://ufdeploy/ufdeploy-jenkins/ufdeploy-jenkins-sudoers
    - user: root
    - group: root
    - mode: 440

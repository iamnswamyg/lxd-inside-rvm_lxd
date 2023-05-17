ufconfig:
  hosts:  
    ufcolo1-app3-bob:
      networking:
        hostname: ufcolo1-app3-bob
        address: 10.11.11.33
        network: ufcolo1-lan-std
      container:
        host: ufcolo1-app3
        simple-name: bob3
        profiles: 
          - eth0-parent
          - root-16GB
          - vendor-data-22
          - snapshots-workdays-7d
        config:
          boot.autostart: true
      tomcat-webapps:
        bobweb-prod-forwarder: bobweb
      tomcat-name: ufcolo1-app3-bob
      tomcat-worker: app3-bob
      tomcat-lbworker: bob-slb-worker
      tomcat-route: app3
      tomcat-restart-calls:
        - "bobweb-prod-forwarder/webapp?Action=act_SystemActions_Ping"
      tomcat-restart-cron-min: 27
      tomcat-config-name: tomcat-tar-bob
      filebeat-log-locations:
        bobweb: /opt/tomcat/logs/bobweb-json*.log
      nagios:
        hostgroups: { lxd-instance, app-server-bob, mail-out }
        parents: { ufcolo1-app3 }
  networks:
    ufcolo1-lan-std:
      site: ufcolo1
      netmask: 255.255.0.0
      network: 10.11.0.0
      network-prefix: 16
      broadcast: 10.11.255.255
      gateway: 10.11.0.1
      dns-nameservers:
        - 10.11.10.1
        - 10.11.10.2
      dns-search: ufprod.lan
      ntp-servers:
        - ufcolo1-dmzprod1
        - ufcolo1-dmzprod2
      mail-fallback-relay: ufcolo2-misc2-mail

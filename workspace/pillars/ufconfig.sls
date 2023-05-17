ufconfig:
  tomcat-versions:
    majorversion: 9
    version: 9.0.64
  applications:
    bobweb:
      ping:
        url: webapp?Action=act_SystemActions_Ping
        expected-response: PONG!!!
      workers:
        load-balancer:
          name: bob-slb-worker
          sticky: True
      servers:
        ufcolo1:
          config: prod
          web-servers:
            - ufcolo1-dmzprod1-webbob1
            - ufcolo1-dmzprod2-webbob1
            - ufcolo1-dmzprod3-webbob1
          app-servers:
            app1-bob:
              route: app1
              host: ufcolo1-app1-bob
            app2-bob:
              route: app2
              host: ufcolo1-app2-bob
            app3-bob:
              route: app3
              host: ufcolo1-app3-bob

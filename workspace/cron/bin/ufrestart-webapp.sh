#!/bin/bash

###############################################################################
# Set worker status
# $1 APACHE JKSTATUS URL
# $2 APACHE WORKER
# $3 APACHE LB WORKER
# $4 STATUS
function jkstatus {
    echo "Setting $1 worker $2/$3 status to $4 (0=Active,1=Disabled and 2=Stopped)";
    RESULT=$(wget --no-check-certificate --timeout=10 --tries=5 -qO- "$1/ufjkstatus?cmd=update&from=list&w=$3&sw=$2&vwa=$4&mime=txt");
    if [ "$RESULT" = 'Result: type=OK message="Action finished"' ]; then
      echo "app1 stopped on web1:" $RESULT;
      return 0;
    else
      echo "failed to stop app1 on web1:" $RESULT;
      return 1;
    fi
}

###############################################################################
# Restarting tomcat
# Stopping apache workers
{%- for webServer, workerInfo in workers | dictsort %}
{%- for worker, lbworker in workerInfo | dictsort %}
jkstatus "https://{{ webServer }}.got.ufinternal.net:8091" "{{ worker }}" "{{ lbworker }}" "2"
{%- endfor %}
{%- endfor %}

# Restarting tomcat
sudo service {{ service }} restart
echo "Waiting for 8s..."
sleep 8
echo "Poking webapps..."
{% for call in calls %}
URL="http://localhost:8080/{{ call }}"
echo "calling: $URL"
wget -q -O- "$URL"
{% endfor %}

echo "Waiting for 4s..."
sleep 4
# Starting apache workers
{%- for webServer, workerInfo in workers | dictsort %}
{%- for worker, lbworker in workerInfo | dictsort %}
jkstatus "https://{{ webServer }}.got.ufinternal.net:8091" "{{ worker }}" "{{ lbworker }}" "0"
{%- endfor %}
{%- endfor %}

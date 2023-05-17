# !/bin/bash

SITE=$1

function quit() {
  echo "$(date) Failed: $1"
  exit 1
}

function runcmd() {
  CMD="$1 $2"
  echo ">>>>>> $CMD <<<<<<"
  $CMD
  if [ $? -ne 0 ]; then
    quit "$CMD"
  else
    echo ">>>>>> $(date) Success: $CMD <<<<<<"
  fi
}

function runee() {
  CMD="ufee-status.sh ufenv-$1-prod-ee.sh $2-app1-ee ACTIVE"
  echo ">>>>>> $CMD <<<<<<"
  $CMD
  echo ">>>>>> $(date) Done: $CMD <<<<<<"
}

CHECK_SITE_STATUSES=""
CHECK_SITE_STATUS_URLS_RETURN_VALUE=""
function checksitestatusurls() {
  CHECK_SITE_STATUS_URLS_RETURN_VALUE=""

  local return_status

  for url in $1; do
    local webserver=$(echo "$url" | sed 's/http:\/\/\([A-Za-z0-9-]*\).*/\1/')
    local status=$(wget -qO- $url)
    CHECK_SITE_STATUSES="$webserver: $status, $CHECK_SITE_STATUSES"
    if [[ $status == "INACTIVE" ]] && [[ $return_status != "ACTIVE" ]]; then
      return_status="INACTIVE"
    elif [[ $status == "ACTIVE" ]] && [[ $return_status != "INACTIVE" ]]; then
      return_status="ACTIVE"
    else
      return 1
    fi
  done

  CHECK_SITE_STATUS_URLS_RETURN_VALUE="$return_status"
}

if [[ "$SITE" = "auto" ]]; then
  WEEK=$((10#$(date +%V)))
  if [ $((WEEK%2)) -ne 0 ]; then 
    SITE="ufcolo1"
  else 
    SITE="ufcolo2"
  fi
  echo "Auto detecting site based on iso week (odd week ufcolo1, even week ufcolo2)"
  echo "Week: $WEEK"
  echo "Site: $SITE"
fi

if [[ "$SITE" != "ufcolo1" ]] && [[ "$SITE" != "ufcolo2" ]]; then
  quit "Invalid site argument: '$SITE', only 'ufcolo1' or 'ufcolo2' is valid values"
fi
S1WEB_STATUS_URLS="
{%- for server in salt['ufapplication.webservers'](None, 'ufcolo1', 'prod') %}
http://{{ server }}.got.ufinternal.net:8090/SITE_STATUS
{%- endfor %}
"

S2WEB_STATUS_URLS="
{%- for server in salt['ufapplication.webservers'](None, 'ufcolo2', 'prod') %}
http://{{ server }}.got.ufinternal.net:8090/SITE_STATUS
{%- endfor %}
"

# Check status
checksitestatusurls "$S1WEB_STATUS_URLS" || quit "Inconsistent webserver SITE_STATUS, $CHECK_SITE_STATUSES"
S1WEB_STATUS=$CHECK_SITE_STATUS_URLS_RETURN_VALUE

checksitestatusurls "$S2WEB_STATUS_URLS" || quit "Inconsistent webserver SITE_STATUS, $CHECK_SITE_STATUSES"
S2WEB_STATUS=$CHECK_SITE_STATUS_URLS_RETURN_VALUE

if [[ $S1WEB_STATUS == "ACTIVE" ]]; then
  S1_SITE="ufcolo1"
elif [[ $S1WEB_STATUS == "INACTIVE" ]]; then
  S1_SITE="ufcolo2"
else
  quit "Inconsisten webserver SITE_STATUS, $CHECK_SITE_STATUSES" 
fi
if [[ $S2WEB_STATUS == "ACTIVE" ]]; then
  S2_SITE="ufcolo2"
elif [[ $S2WEB_STATUS == "INACTIVE" ]]; then
  S2_SITE="ufcolo1"
else
  quit "Inconsisten webserver SITE_STATUS, $CHECK_SITE_STATUSES" 
fi
if [[ $S1_SITE == $S2_SITE ]]; then
  if [[ $S1_SITE != $SITE ]]; then
    echo "Switching from $S1_SITE to $SITE"
  else
    quit "Site $SITE already active!" 
  fi
else
  quit "Inconsisten webserver SITE_STATUS, $CHECK_SITE_STATUSES" 
fi


runcmd ufswitchover-ufoee-prod-ee.sh $SITE
runcmd ufswitchover-hitee-prod-ee.sh $SITE
runcmd ufswitchover-ufofs-prod-ufofs.sh $SITE
runcmd ufswitchover-hitweb-prod-hit.sh $SITE
runcmd ufswitchover-bobweb-prod-bob.sh $SITE
runcmd ufswitchover-ufoweb-prod-ufo.sh $SITE

runcmd ufactivate-site.sh $SITE

runee ufoee $SITE
runee hitee $SITE

#!/bin/bash

#Login to dropbox: user: max.almgren@unifaun.com pass: pasta123

SCRIPT=$1
APP_NAME=$2
DIST_NAME=$3
LINKS=$4

if [[ -z $APP_NAME ]] || [[ -z $DIST_NAME ]]; then
  echo "Can't run notify script due to missing arguments"
  exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
  USER="ufdeploy"
else
  USER=$SUDO_USER
fi

if [[ "$SCRIPT" =~ ufdeploy* ]]; then
  TEXT="$USER just **deployed** a new version of $APP_NAME: **$DIST_NAME**"
elif [[ "$SCRIPT" =~ undeploy ]]; then
  TEXT="$USER just **undeployed** an old version of $APP_NAME: **$DIST_NAME**"
  unset LINKS
elif [[ "$SCRIPT" =~ ufwarmup ]]; then
  TEXT="$USER just run **warmup** on $APP_NAME for version: **$DIST_NAME**"
else
  TEXT="$USER just **activated** a new version of $APP_NAME: **$DIST_NAME**"
fi

imageurl="https://www.unifaunonline.com/resources/dev/"
userimage=''
case $USER in
    "max")
        userimage=${imageurl}'max.jpg' ;;
    "karin")
        userimage=${imageurl}'karin.jpg' ;;
    "carl")    
        userimage=${imageurl}'carlf.jpg' ;;
    "danielp")
    	userimage=${imageurl}'danielp.jpg' ;;
    "davidj")
    	userimage=${imageurl}'davidj.jpg' ;;
    "goran")
    	userimage=${imageurl}'goran.jpg' ;;
    "gustafj")
    	userimage=${imageurl}'gustaf.jpg' ;;
    "hans")
    	userimage=${imageurl}'hans.jpg' ;;
    "joakim")
    	userimage=${imageurl}'joakim.jpg' ;;
    "lars")
    	userimage=${imageurl}'lars.jpg' ;;
    "loveh")
    	userimage=${imageurl}'love.jpg' ;;
    "martin")
    	userimage=${imageurl}'martinw.jpg' ;;
    "simonc")
    	userimage=${imageurl}'simonc.jpg' ;;
    "simonk")
    	userimage=${imageurl}'simonk.jpg' ;;
    "victorj")
    	userimage=${imageurl}'victor.jpg' ;;
    "mikaelj")
	userimage=${imageurl}'mikael.jpg' ;;
    "maxm")
	userimage=${imageurl}'maxm.jpg' ;;
    "taniaa")
	userimage=${imageurl}'tania.jpg' ;;
    *)
    	userimage=${imageurl}'unknown.jpg' ;;
esac

payload=$(cat <<-EOF
{
	"@type": "MessageCard",
	"@context": "http://schema.org/extensions",
	"themeColor": "2ad613",
	"summary": "${TEXT}",
	"sections": [
		{
			"activityImage": "$userimage",
			"activityTitle": "${TEXT}",
		}
	],
	"potentialAction": [
		{
			"@type": "ActionCard",
			"name": "Link",
			"actions": [
				{
					"@type": "OpenUri",
					"name": "${LINKS}",
					"targets": [
						{
							"os": "default",
							"uri": "${LINKS}"
						}
					]
				}
			]
		}
	]
}
EOF
)

webhook_url="https://nshift.webhook.office.com/webhookb2/fb49aede-8c7c-43c6-ba6b-3d064cd74c41@92ae5aed-04e6-4286-a8ac-81d5b8f74020/IncomingWebhook/8d2afed0f9aa4771a84e46c8246a2118/1e560760-9d64-4995-98e5-c57478a0e41f"
#webhook_url="https://outlook.office.com/webhook/b4a04d32-9026-4466-9fee-616426e16823@b3f6c046-4d81-49e5-b8c2-ea798fd335c5/IncomingWebhook/bc0a09b6619546fbb2caafbd0b5c8dac/21f6137d-3a81-4897-a155-f7aa90df4467"
#webhook_url="https://outlook.office.com/webhook/f6041a9b-c285-4e13-a7c6-be97ec29e9dd@b3f6c046-4d81-49e5-b8c2-ea798fd335c5/IncomingWebhook/19ab41fee7a042619e01cae07fab3dd3/b58474b0-5cd5-439e-986b-f0623baf6d62"
curl -s -H "Content-Type: applicaion/json" -d "${payload}" "${webhook_url}" > /dev/null

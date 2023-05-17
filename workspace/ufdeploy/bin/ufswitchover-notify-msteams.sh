#!/bin/bash

PREFIX=$1
MESSAGE=$2

if [[ -z $PREFIX ]] || [[ -z $MESSAGE ]]; then
  echo "Can't run notify script due to missing arguments"
  exit 1
fi

userimage='https://www.unifaunonline.com/resources/dev/unknown.jpg'

TEXT="$PREFIX $MESSAGE"
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
	]
}
EOF
)

webhook_url="https://nshift.webhook.office.com/webhookb2/fb49aede-8c7c-43c6-ba6b-3d064cd74c41@92ae5aed-04e6-4286-a8ac-81d5b8f74020/IncomingWebhook/510ceebb8a0644a88020e7b29c41b36e/1e560760-9d64-4995-98e5-c57478a0e41f"
#webhook_url="https://unifaun.webhook.office.com/webhookb2/b4a04d32-9026-4466-9fee-616426e16823@b3f6c046-4d81-49e5-b8c2-ea798fd335c5/IncomingWebhook/930687ff3b6a4cd1a6bc97608be71585/c258d63f-9ae1-48b5-bab1-03f5d37ffd2e"
#webhook_url="https://outlook.office.com/webhook/b4a04d32-9026-4466-9fee-616426e16823@b3f6c046-4d81-49e5-b8c2-ea798fd335c5/IncomingWebhook/c4a79807454e491ca4ef7a2c38161397/21f6137d-3a81-4897-a155-f7aa90df4467"
curl --max-time 20 -s -H "Content-Type: application/json" -d "${payload}" "${webhook_url}" > /dev/null
exit 0
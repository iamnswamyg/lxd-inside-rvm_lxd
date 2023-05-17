#!/bin/bash

# This script is invoked via ssh from Jenkins (via Jenkinsfile). #see ufdeploy-jenkins.id_rsa.pub
#            sshCommand remote: remote, command: "deploy ${BUILD_NUMBER} 'UFO DistDevTest' ${distName} ${shaSum} UfoEdiExchangeDist-3.0 ufoee"

function log {
  echo "$(date) $1"
}

# Run with sudo #see ufdeploy-jenkins-sudoers

# Sanitize input string to avoid injection!
declare -a "TMP1=($( echo "$1" | sed 's/[][`~!@#$%^&*():;<>.,?/\|{}=+-]/\\&/g' ))"

DEPLOY=${TMP1[0]}           # deploy
JENKINS_BUILDNO=${TMP1[1]}  # 182
JENKINS_JOBNAME=${TMP1[2]}  # UFO DistDevTest | UFOEE DistExtTest
TARFILE=${TMP1[3]}          # sdfjskdfj.tar
SHASUM=${TMP1[4]}           # 8e7df23...
ANT_PROJECT=${TMP1[5]}      # UfoWebDist-3.0 / UfoEdiExchange-3.0
ANT_APP_NAME=${TMP1[6]}     # ufoweb / ufoee

LOCK_TIMEOUT=300

function usage {
    echo "USAGE: $0 '[JENKINS_BUILDNO] [JENKINS_JOBNAME] [TARFILE_NAME] [SHA256SUM OF TARFILE]' [ANT_PROJECT] [ANT_APP_NAME]"
    echo "Example:"
    echo "$0 '153 \"UFO DistDevTest\" \"ufoweb-devtest-202107161059-mattiasn.dist.tar\" bcffe7676a5a...' UfoWebDist-3.0 ufoweb"
    echo "$0 '193 \"UFOEE DistExtTest\" \"ufoee-postitest-202201131422-extern.dist.tar\" bcffe7676a5a...' UfoEdiExchangeDist-3.0 ufoee"
    exit 1
}

if [ "$DEPLOY" != "deploy" ]; then
    log "ERROR: DEPLOY not set"
    usage
fi
if [ "x$TARFILE" = "x" ]; then
    log "ERROR: TARFILE not set"
    usage
fi
if [ "x$JENKINS_BUILDNO" = "x" ]; then
    log "ERROR: JENKINS_BUILDNO not set"
    usage
fi
if [ "x$SHASUM" = "x" ]; then
    log "ERROR: SHASUM not set"
    usage
fi
if [ "x$ANT_PROJECT" = "x" ]; then
    log "INFO: ANT_PROJECT set to default: UfoWebDist-3.0"
    ANT_PROJECT="UfoWebDist-3.0"
fi
if [ "x$ANT_APP_NAME" = "x" ]; then
    log "INFO: ANT_APP_NAME set to default: ufoweb"
    ANT_APP_NAME="ufoweb"
    usage
fi

log "JENKINS_BUILDNO: ${JENKINS_BUILDNO}"
log "JENKINS_JOBNAME: ${JENKINS_JOBNAME}"
log "TARFILE: ${TARFILE}"
log "ANT_PROJECT: ${ANT_PROJECT}"
log "ANT_APP_NAME: ${ANT_APP_NAME}"

TMP_DIR=/tmp/ufdeploy-jenkins.tmp.$$
HOST=https://10.100.31.63
WGET="/usr/bin/wget -q --no-check-certificate"

DIST=`echo $TARFILE | sed -e 's/\(.*\)\.dist.tar$/\1/'`
ANT_=`echo $DIST | awk -F- '{print $2}'`  # "devtest" / "postitest"
ANT_CONFIG_NAME=`echo $DIST | awk -F- '{print $2}'`  # "devtest" / "postitest"
ANT_DIST_TARGET=`echo $DIST | awk -F- '{print $4}'`  # "mattiasn" / "extern"
ANT_TSTAMP=`echo $DIST | awk -F- '{print $3}'`       # "202107161059"
ANT_DIST_NAME="${ANT_CONFIG_NAME}-${ANT_TSTAMP}"

if [ $ANT_APP_NAME == "ufoweb" ]; then
    UFAPP_ACTIVATE_CMD="/usr/local/bin/ufactivate-app.sh"
    UFAPP_DEPLOY_CMD="/usr/local/bin/ufdeploy.sh"
    UFAPP_UNDEPLOY_CMD="/usr/local/bin/ufapp-undeploy.sh $ANT_DIST_TARGET"
    UFAPP_LIST_CMD="/usr/local/bin/ufapp-list.sh ${ANT_DIST_TARGET} ${ANT_APP_NAME} ${ANT_CONFIG_NAME}"
else
    if [ $ANT_APP_NAME == "ufoee" ]; then
	UFAPP_ACTIVATE_CMD="/usr/local/bin/ufactivate-ee.sh"
	UFAPP_DEPLOY_CMD="/usr/local/bin/ufdeploy-ee.sh"
	echo $TARFILE|grep extern >/dev/null
	if [ $? -eq 0 ]; then
	    UFAPP_UNDEPLOY_CMD="/usr/local/bin/ufee-undeploy.sh extern"
	else
	    UFAPP_UNDEPLOY_CMD="/usr/local/bin/ufee-undeploy.sh ee"
	fi
	UFAPP_LIST_CMD="/usr/local/bin/uflist-ufoee-${ANT_CONFIG_NAME}-extern.sh"
    else
	log "Unknown ANT_DIST_NAME: ${ANT_DIST_NAME}"
	usage
    fi
fi

LOCK_NAME=`echo "ufdeploy-jenkins.${ANT_APP_NAME}-${ANT_CONFIG_NAME}-${ANT_DIST_TARGET}"|sed -e 's/[^a-zA-Z0-9\.\-]/_/g'`

if [ "$ANT_CONFIG_NAME" != "devtest" ] && [ "$ANT_DIST_TARGET" != "extern" ]; then
    log "ERROR: Invalid job name ${ANT_CONFIG_NAME}. Only 'devtest' and 'extern' supported for now."
    usage
fi

TARFILE="${ANT_APP_NAME}-${ANT_DIST_NAME}-${ANT_DIST_TARGET}.dist.tar"
URL="${HOST}/job/DistBuilds/job/${JENKINS_JOBNAME}/${JENKINS_BUILDNO}/artifact/projects/${ANT_PROJECT}/dist/${ANT_CONFIG_NAME}/${TARFILE}"

mkdir -p $TMP_DIR
function terminate {
    rm -rvf $TMP_DIR
    rm -f /var/lock/$LOCK_NAME
}

trap terminate EXIT



function runit {
    log "List existing"

    ${UFAPP_LIST_CMD} >$TMP_DIR/list
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to list currently installed"
        exit 2
    fi

    UNDEPLOY_LIST=`grep 'Application: ' $TMP_DIR/list | awk '{print $2}'|xargs echo`
    log "Found existing apps: $UNDEPLOY_LIST"

    TODEPLOY="${ANT_APP_NAME}-${ANT_DIST_NAME}"
    for VER in $UNDEPLOY_LIST; do
        if [ "$VER" = "$TODEPLOY" ]; then
            log "ERROR: $TARFILE is already deployed"
            exit 3
        fi
    done


    log "Downloading $URL"
    (cd $TMP_DIR/; ${WGET} "$URL")
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to download $URL"
        exit 4
    fi

    (cd $TMP_DIR; echo "$SHASUM $TARFILE" | /usr/bin/sha256sum --check --status)

    if [ $? -ne 0 ]; then
        log "ERROR: Checksum failed for $TARFILE"
        exit 5
    fi

    log "Deploying new version"
    ${UFAPP_DEPLOY_CMD} $TMP_DIR/$TARFILE
    
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to deploy"
        exit 6
    fi


    log "Activating new version"

    ${UFAPP_ACTIVATE_CMD} $TARFILE

    if [ $? -ne 0 ]; then
        log "ERROR: Failed to activate $TARFILE"
        exit 7
    fi

    log "Undeploying old version"

    FAIL_UNDEPLOY=0
    for VER in ${UNDEPLOY_LIST}; do
        log "Undeploying ${VER} .."
	${UFAPP_UNDEPLOY_CMD} $VER
	
        if [ $? -ne 0 ]; then
            FAIL_UNDEPLOY=1
            log "WARN: Failed to undeploy $VER"
        fi
    done

    if [ $FAIL_UNDEPLOY -ne 0 ]; then
        exit 8
    fi
}

log "Locking /var/lock/$LOCK_NAME"
(
    flock --verbose -x -w $LOCK_TIMEOUT 200
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to lock $LOCK_NAME"
        exit 17
    fi
    runit
    exit 0
) 200> /var/lock/$LOCK_NAME

exit $?

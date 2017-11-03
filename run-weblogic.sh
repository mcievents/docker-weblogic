#!/bin/bash
set -e

WL_HOME=/opt/weblogic/wlserver

# See if WebLogic domain already exists.
if [ ! -d "/srv/weblogic/$WEBLOGIC_DOMAIN/config" ]; then
    # It does not.  Create it.
    # Find or generate domain admin password.
    if [ -z "$WEBLOGIC_PWD" ]; then
        if [ -f /run/secrets/weblogic_admin_password ]; then
            export WEBLOGIC_PWD=`cat /run/secrets/weblogic_admin_password`
            echo "Weblogic domain $WEBLOGIC_DOMAIN admin password read from Docker secret."
        else
            export WEBLOGIC_PWD=${WEBLOGIC_PWD:-"`openssl rand -base64 12`"}
            echo "Generated random admin password for Weblogic domain $WEBLOGIC_DOMAIN."
            echo "WEBLOGIC DOMAIN $WEBLOGIC_DOMAIN ADMIN PASSWORD: $WEBLOGIC_PWD"
        fi
    else
        echo "Weblogic domain $WEBLOGIC_DOMAIN admin password read from environment."
    fi

    $WL_HOME/common/bin/wlst.sh -skipWLSModuleScanning <<EOF
        readTemplate("$WL_HOME/common/templates/domains/wls.jar")
        set('Name', '$WEBLOGIC_DOMAIN')
        setOption('DomainName', '$WEBLOGIC_DOMAIN')
        cd('/Security/$WEBLOGIC_DOMAIN/User/weblogic')
        cmo.setPassword('$WEBLOGIC_PWD')
        setOption('OverwriteDomain', 'true')
        writeDomain('/srv/weblogic/$WEBLOGIC_DOMAIN')
        closeTemplate()
        exit()
EOF

    # Execute custom user setup scripts
    SETUP_SCRIPT_DIR=/opt/weblogic/scripts/setup
    if [ -d $SETUP_SCRIPT_DIR ] && [ -n "$(ls -A $SETUP_SCRIPT_DIR)" ]; then
        echo ""
        echo "Executing user-defined setup scripts..."

        for f in $SETUP_SCRIPT_DIR/*; do
            case "$f" in
                *.sh)   echo "running $f"; . "$f" ;;
                *.py)   echo "running $f"; $WL_HOME/common/bin/wlst.sh "$f" ;;
                *)      echo "ignoring $f" ;;
            esac
        done
        echo ""
    fi
fi

cd /srv/weblogic/$WEBLOGIC_DOMAIN
USER_MEM_ARGS=$WEBLOGIC_MEM_ARGS
PRE_CLASSPATH=$WEBLOGIC_PRE_CLASSPATH
. bin/setDomainEnv.sh
exec $JAVA_HOME/bin/java $JAVA_VM $MEM_ARGS \
    -Dweblogic.Name=$SERVER_NAME \
    -Djava.security.policy=$WL_HOME/server/lib/weblogic.policy \
    $JAVA_OPTIONS $PROXY_SETTINGS $SERVER_CLASS

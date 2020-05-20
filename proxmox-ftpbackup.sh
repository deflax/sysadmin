#!/usr/bin/env bash
### FTP config
FTPHOST="your.ftp.com"
FTPPATH="dump/"
FTPUSER=""
FTPPASS=""
### Purge after x days
PURGE=3
### Storage ID to move
STORAGE="local-backup"

##### CONFIG END #####

### FUNCTIONS
function log {
    echo "[HOOK] $*"
}
function purge_ftp {
    VM=$1
    log "PURGE for VM ${VM} started."

    PURGEDATE=$(date --date="${PURGE} days ago" +%s)
    FILES=$(curl -s -u "${FTPUSER}:${FTPPASS}" --list-only "ftp://${FTPHOST}/${FTPPATH}" | sort)
    RETURNCODE=$?
    if [[ $RETURNCODE -ne 0 ]]; then
        log "    LIST: ftp://${FTPHOST}/${FTPPATH} - FAILED (curl): $RETURNCODE"
        return $RETURNCODE
    fi
    for FILE in ${FILES[@]}; do
        SPLITFILE="${FILE/./ }"; SPLITFILE="${SPLITFILE//-/ }"; SPLITFILE=(${SPLITFILE//_/-})

        VMSTR="${SPLITFILE[2]}"
        DATESTR="${SPLITFILE[3]}"
        TIMESTR="${SPLITFILE[4]}"; TIMESTR="${TIMESTR//-/:}"
        if [[ $(date --date="$DATESTR $TIMESTR" +%s) -lt $PURGEDATE && "$VMSTR" == "$VM" ]]; then
            curl -s -u "${FTPUSER}:${FTPPASS}" --head -Q "-DELE ${FTPPATH}${FILE}" "ftp://${FTPHOST}"
            RETURNCODE=$?
            if [[ $RETURNCODE -ne 0 ]]; then
                log "    DELETE: $FILE - FAILED (curl): $RETURNCODE"
                return $RETURNCODE
            else
                log "    DELETE: $FILE - SUCCESS"
            fi
        elif [[ "$VMSTR" == "$VM" ]]; then
            log "    KEEP: $FILE - not older than ${PURGE} days"
        fi
    done
    return 0
}
function upload_ftp {
    FILE=$1
    log "UPLOAD for ${FILE} started."

    RETURNCODE=1
    TRIES=0
    while [[ $RETURNCODE -ne 0 && $TRIES -lt 3 ]]; do
        ((TRIES++))
        curl -s -u "${FTPUSER}:${FTPPASS}" --keepalive-time 30 -T "$FILE" "ftp://${FTPHOST}/${FTPPATH}"
        RETURNCODE=$?
        if [[ $RETURNCODE -ne 0 ]]; then
            # try to mitigate curl (28): Timeout, curl(55)
            # usually file transfers fine, but control channel is killed by the firewall
            FILENAME=$(basename "${FILE}")
            LOCALSIZE=$(stat --printf="%s" "${FILE}" | tr -d '[[:space:]]')
            REMOTESIZE=$(curl -sI -u "${FTPUSER}:${FTPPASS}" "ftp://${FTPHOST}/${FTPPATH}${FILENAME}" | awk '/Content-Length/ { print $2 }' | tr -d '[[:space:]]')
            log "    UPLOAD #${TRIES}: $FILE to ftp://${FTPHOST}/${FTPPATH} - local: ${LOCALSIZE}, remote: ${REMOTESIZE}"
            if [[ "$REMOTESIZE" -eq "$LOCALSIZE" ]]; then
                log "    UPLOAD #${TRIES}: $FILE to ftp://${FTPHOST}/${FTPPATH} - WARN (curl): $RETURNCODE, but seems complete"
                RETURNCODE=0
            else
                log "    UPLOAD #${TRIES}: $FILE to ftp://${FTPHOST}/${FTPPATH} - FAILED (curl): $RETURNCODE"
                if [[ $RETURNCODE -eq 55 ]]; then
                    curl -s -u "${FTPUSER}:${FTPPASS}" --head -Q "-DELE ${FTPPATH}${FILENAME}" "ftp://${FTPHOST}"
                fi
            fi
        fi
    done
    if [[ $RETURNCODE -ne 0 ]]; then
        log "    UPLOAD: $FILE to ftp://${FTPHOST}/${FTPPATH} - FAILED PERMANENTLY"
    else
        log "    UPLOAD: $FILE to ftp://${FTPHOST}/${FTPPATH} - SUCCESS"
    fi
    return $RETURNCODE
}

### MAIN
PHASE=$1
if [[ "$PHASE" == "job-start" || "$PHASE" == "job-end" || "$PHASE" == "job-abort" ]]; then
    #DUMPDIR
    #STOREID

    exit 0
fi
if [[ "$PHASE" == "backup-start" || "$PHASE" == "backup-end" || "$PHASE" == "backup-abort" || "$PHASE" == "log-end" || "$PHASE" == "pre-stop" || "$PHASE" == "pre-restart" || "$PHASE" == "post-restart" ]]; then
    MODE=$2 # stop,suspend,snapshot
    VMID=$3
    #DUMPDIR
    #STOREID
    #VMTYPE # openvz,qemu
    #HOSTNAME

    if [[ "$PHASE" == "backup-end" && "$STOREID" == "$STORAGE" ]]; then
        #TARFILE
        log "transfer backup archive of VM ${VMID} to FTP"
        upload_ftp "$TARFILE"
        RETURNCODE=$?  
        if [[ $RETURNCODE -ne 0 ]]; then exit $RETURNCODE; fi
        log "remove local backup archive of VM ${VMID}"
        rm "$TARFILE"

        log "purge old backup and log files of VM ${VMID} from FTP"
        purge_ftp $VMID
        RETURNCODE=$?
        exit $RETURNCODE
    fi

    if [[ "$PHASE" == "log-end" && "$STOREID" == "$STORAGE" ]]; then
        #LOGFILE
        log "transfer log file of VM ${VMID} to FTP"
        upload_ftp "$LOGFILE"
        RETURNCODE=$?
        if [[ $RETURNCODE -ne 0 ]]; then exit $RETURNCODE; fi
        log "remove local log file of VM ${VMID}"
        rm "$LOGFILE"

        exit $RETURNCODE
    fi

    exit 0
fi
# manual tasks

if [[ $PHASE == "manual-cleanup" ]]; then
        VMID=$2
        if [[ -z $VMID ]]; then
                echo "Usage: $(basename $0) manual-cleanup <VMID>"
                exit 1
        fi

        log "purge old backup and log files of VM ${VMID} from FTP"
        purge_ftp $VMID
        RETURNCODE=$?
        log "purge old backup and log files of VM ${VMID} from local storage"
        rm -r ${STORAGEDIR}/dump/vzdump-*-${VMID}-*
        exit $RETURNCODE
fi

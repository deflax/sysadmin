#!/bin/bash

REG_USER_REMOTE=KUR
REG_PASS_REMOTE=MUR

REG_HOST_REMOTE=HOSTZZ
export REG_HOST_REMOTE

    REG_ACCOUNT="${REG_USER_REMOTE}:${REG_PASS_REMOTE}"
    REG_B64_ACCOUNT=`echo $REG_ACCOUNT | base64 -w 0`
    export REG_B64_ACCOUNT
    REG_B64_CONFIG=`cat dockerconfig.json | envsubst | base64 -w 0`
    export REG_B64_CONFIG
    cat registrykey.yaml | envsubst

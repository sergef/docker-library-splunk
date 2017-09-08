#!/bin/bash
set -e

_SPLUNK_PW=${SPLUNK_PASSWORD:-changeme}

touch ${SPLUNK_HOME}/etc/.ui_login # Disable the "first time signing in" message
${SPLUNK_HOME}/bin/splunk edit user admin -password ${_SPLUNK_PW} -auth admin:changeme --accept-license # Accept lic at first command
${SPLUNK_HOME}/bin/splunk enable listen 9997 -auth admin:${_SPLUNK_PW}

[[ ${SPLUNK_ENTERPRISE} ]] || ${SPLUNK_HOME}/bin/splunk edit licenser-groups Free -is_active 1

echo -e "\nOPTIMISTIC_ABOUT_FILE_LOCKING = 1\n" >> ${SPLUNK_HOME}/etc/splunk-launch.conf
echo -e "[default]\n[settings]\n\n" >> ${SPLUNK_HOME}/etc/system/local/web.conf

[[ ${SPLUNK_ENABLE_VERSION_CHECK} ]] || echo "updateCheckerBaseURL = 0" >> ${SPLUNK_HOME}/etc/system/local/web.conf
[[ ${SPLUNK_WEB_PATH} ]] && echo "root_endpoint = /${SPLUNK_WEB_PATH}" >> ${SPLUNK_HOME}/etc/system/local/web.conf

if [[ ${SPLUNK_SSO} ]]; then
  # Get docker proxy ip
  _PROXY_IP=$(getent hosts proxy | cut -d' ' -f1)
  [[ ${_PROXY_IP} ]] || (echo "You need to link a proxy, or disable SSO"; exit 1)
  echo -e "remoteUser = ${SPLUNK_SSO_REMOTEUSER}\ntrustedIP = ${_PROXY_IP}" >> ${SPLUNK_HOME}/etc/system/local/web.conf

  sed "/\[general\]/a trustedIP = 127.0.0.1" -i ${SPLUNK_HOME}/etc/system/local/server.conf
  ${SPLUNK_HOME}/bin/splunk add user "${SPLUNK_SSO_ADMIN}" -role admin -password password
fi

if [[ ${SPLUNK_SSL} ]]; then
  echo "enableSplunkWebSSL = True" >> ${SPLUNK_HOME}/etc/system/local/web.conf
fi

[[ ${SPLUNK_SERVERNAME} ]] && sed "s/\(serverName = \).*/\1${SPLUNK_SERVERNAME}/" -i ${SPLUNK_HOME}/etc/system/local/server.conf
[[ ${SPLUNK_SERVERNAME} ]] && sed "s/\(host = \).*/\1${SPLUNK_SERVERNAME}/" -i ${SPLUNK_HOME}/etc/system/local/inputs.conf

[[ ${SPLUNK_SESSION_TIMEOUT} ]] && sed "/\[general\]/a sessionTimeout = ${SPLUNK_SESSION_TIMEOUT}" -i ${SPLUNK_HOME}/etc/system/local/server.conf

${SPLUNK_HOME}/bin/splunk add tcp 514 -sourcetype syslog -resolvehost true
${SPLUNK_HOME}/bin/splunk add udp 514 -sourcetype syslog -resolvehost true
${SPLUNK_HOME}/bin/splunk add udp 8517 -sourcetype json_no_timestamp -resolvehost true

if [ -e /data ]; then
  ${SPLUNK_HOME}/bin/splunk add monitor /data
fi

if [ -e /license.lic ]; then
  ${SPLUNK_HOME}/bin/splunk add licenses /license.lic
fi

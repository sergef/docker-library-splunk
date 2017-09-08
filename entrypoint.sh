#!/bin/bash
set -e

sed \
  "s|%SPLUNK_TTG_MACHINE_TOKEN%|${SPLUNK_TTG_MACHINE_TOKEN}|g" \
  ${SPLUNK_HOME}/etc/apps/splunk_httpinput/local/inputs.conf.tmpl > \
  ${SPLUNK_HOME}/etc/apps/splunk_httpinput/local/inputs.conf

# 'docker stop' signal handling.
trap '[ -e "/opt/splunk/var/run/splunk/splunkweb.pid" ] && /opt/splunk/bin/splunk stop; exit 0' SIGTERM

# Using splunk --nodaemon isnt working correctly and will never start the web-service.
/opt/splunk/bin/splunk start && tail -f /opt/splunk/var/log/splunk/splunkd.log

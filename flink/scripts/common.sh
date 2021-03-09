#! /bin/bash
###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

cobli_verbosity_level=${COBLI_FLINK_VERBOSITY_LEVEL:-0}
flink_home=${FLINK_HOME:-"/opt/flink"}

missing_env_msg="ERROR: Could not find environment variable"
job_name="${FLINK_CONF_HIGH_AVAILABILITY_CLUSTER_ID:?$missing_env_msg}"

green_color='\033[1;32m'
cyan_color='\033[0;36m'
no_color='\033[0m'
red_color='\033[0;31m'
yellow_color='\033[1;33m'

clean_protocol() {
  local in_path out_path
  in_path="$1"
  echo "$in_path" | sed "s!^\([^ ]\)*://!!"
}

log_debug() {
  if [ "$cobli_verbosity_level" -ge 3 ]; then
    timestamp="$(date --rfc-3339=ns)"
    prefix="${cyan_color}${timestamp} ${cobli_script}: <DEBUG>"
    sufix="${no_color}"
    echo -e "${prefix} $*${sufix}" 1>&2
  fi
}

log_info() {
  if [ "$cobli_verbosity_level" -ge 2 ]; then
    timestamp="$(date --rfc-3339=ns)"
    prefix="${green_color}${timestamp} ${cobli_script}: <INFO>"
    sufix="${no_color}"
    echo -e "${prefix} $*${sufix}" 1>&2
  fi
}

log_warn() {
  if [ "$cobli_verbosity_level" -ge 1 ]; then
    timestamp="$(date --rfc-3339=ns)"
    prefix="${yellow_color}${timestamp} ${cobli_script}: <WARN>"
    sufix="${no_color}"
    echo -e "${prefix} $*${sufix}" 1>&2
  fi
}

log_err() {
    timestamp="$(date --rfc-3339=ns)"
    prefix="${red_color}${timestamp} ${cobli_script}: <ERROR>"
    sufix="${no_color}"
    echo -e "${prefix} $*${sufix}" 1>&2
}

ensure_flink_config() {
  if [ "${COBLI_FLINK_CONF_TEMPLATE_PATH:-undefined}" != "undefined" ]; then
    msg="Generating flink-conf.yaml from template:"
    log_info "$msg <$COBLI_FLINK_CONF_TEMPLATE_PATH>"
    envsubst \
      < "$COBLI_FLINK_CONF_TEMPLATE_PATH" \
      > "$flink_home/conf/flink-conf.yaml"
  fi
}


## H.A. variables
default_ha_sp="/mnt/$job_name-states/savepoints"
env_hs_sp_path=$(clean_protocol "$FLINK_CONF_STATE_SAVEPOINTS_DIR")
ha_savepoint_path="${env_hs_sp_path:-$default_ha_sp}"
default_sp_ref="${ha_savepoint_path}/last_savepoint.cobli"
savepoint_ref_path="${COBLI_FLINK_SAVEPOINT_REF_PATH:-$default_sp_ref}"

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

green_color='\033[1;32m'
cyan_color='\033[0;36m'
no_color='\033[0m'
red_color='\033[0;31m'
yellow_color='\033[1;33m'

log_debug() {
  if [ "$cobli_verbosity_level" -ge 3 ]; then
    echo -e "${cyan_color}${cobli_script}: <DEBUG> $*${no_color}" 1>&2
  fi
}

log_info() {
  if [ "$cobli_verbosity_level" -ge 2 ]; then
    echo -e "${green_color}${cobli_script}: <INFO> $*${no_color}" 1>&2
  fi
}

log_warn() {
  if [ "$cobli_verbosity_level" -ge 1 ]; then
    echo -e "${yellow_color}${cobli_script}: <WARN> $*${no_color}" 1>&2
  fi
}

log_err() {
  echo -e "${red_color}${cobli_script}: <ERROR> $*${no_color}" 1>&2
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

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

set -e

cobli_script="COBLI_ENTRYPOINT"

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common.sh

submit_job() {
  log_info "> Submiting job..."
  ensure_flink_config
  log_debug "> Submission command:"
  log_debug "> \"$flink_home/bin/standalone-job.sh\" \"$@\" 1>&2 &"
  "$flink_home/bin/standalone-job.sh" "$@" 1>&2 &
  log_info "> Job submited"
}

ensure_ha_directories() {
  log_info "> Ensuring directories existence..."
  mkdir -p "$@"
  log_info "> Directories present"
}

get_savepoint_ref() {
  local savepoint_ref_path savepoint_path
  savepoint_ref_path="$1"
  savepoint_path=''

  log_debug "Looking for savepoints in <$savepoint_ref_path>"
  if [ -f "$savepoint_ref_path" ]; then
    log_info "> Savepoint reference file found"
    log_info "> Geting savepoint path..."
    savepoint_path=$(sed 's/#.*//g' < "$savepoint_ref_path")
    log_info "> Got savepoint: <$savepoint_path>"
  else
    log_warn "> Savepoint file not fount"
  fi
  echo "$savepoint_path"
}

get_jar_location() {
  local jar_prefix jar_path flink_lib_path
  jar_prefix="$1"
  flink_lib_path="$flink_home/lib"
  jar_path=$(find "$flink_lib_path" -name "${jar_prefix}*.jar")
  if [ "${jar_path:-undefined}" == "undefined" ]; then
    msg="Couldi not find a file with prefix <$jar_prefix> in <$flink_lib_path>"
    log_err "$msg"
    exit 1
  fi
  echo "$jar_path"
}

clean_zookeeper_data() {
  local zk_host zk_root_path job_name
  zk_host="$1"
  zk_root_path="$2"
  job_name="$3"

  local zk_clean_cmd
  zk_clean_cmd="rmr $zk_root_path/$job_name"

  local zk_jars_0 zk_jars_1 zk_jars zk_class
  zk_jars_0=$(get_jar_location "org.apache.zookeeper.zookeeper")
  zk_jars_1=$(get_jar_location "org.slf4j.slf4j-api")
  zk_jars="$zk_jars_0:$zk_jars_1"
  zk_class="org.apache.zookeeper.ZooKeeperMain"

  log_info "> Cleaning zookeeper path: <$zk_root_path/$job_name>"
  log_debug "> Running command: <$zk_clean_cmd>"
  log_debug "> Using ZK: java -cp <$zk_jars> $zk_class -server <$zk_host>"
  echo "$zk_clean_cmd" | java -cp "$zk_jars" "$zk_class" -server "$zk_host"

  log_info "> Zookeeper cleaned"
}

query_jobmanager_api_for_checkpoints() {
  log_info "> Querying rest api for checkpoints completed"
  local rest_api_addr job_id api_response api_endpoint
  rest_api_addr="$1"
  # TODO get job id from rest api"
  job_id="00000000000000000000000000000000"
  api_endpoint="$rest_api_addr/jobs/$job_id/checkpoints"
  log_debug "> Quering API in address: $api_endpoint"
  api_response=$(curl -s "$api_endpoint"  || true)
  log_debug "> Api response: <$api_response>"
  echo "$api_response"
}

get_number_of_checkpoints_completed() {
  log_info "> Getting API response"
  local api_response jq_path rest_api_addr
  rest_api_addr="$1"
  api_response=$(query_jobmanager_api_for_checkpoints "$rest_api_addr")
  jq_path=".counts.completed"
  num_checkpoint_completed=$(echo "$api_response" | jq "$jq_path")
  log_info "> Num of checkpoints completed: <$num_checkpoint_completed>"
  if [ ${num_checkpoint_completed:+x} ]; then
    echo "$num_checkpoint_completed"
  else
    echo "0"
  fi
}

ensure_checkpoint_completion() {
  local rest_api_addr job_name timeout_in_secs interval_in_secs
  rest_api_addr="$1"
  job_name="$2"
  timeout_in_secs="$3"
  interval_in_secs="$4"

  local current_time end_time
  current_time=$(TZ=UTC0 date "+%s")
  end_time=$((current_time + timeout_in_secs))

  local num_checkpoint_completed
  while [ "$current_time" -lt "$end_time" ]; do
    current_time="$(TZ=UTC0 date '+%s')"
    log_info "> Verifying checkpoint creation..."

    num_checkpoint_completed=$(get_number_of_checkpoints_completed \
      "$rest_api_addr")
    if [[ "$num_checkpoint_completed" -gt "0" ]];
    then
      log_info "> Cleaning up savepoint reference"
      return
    fi
    sleep "$interval_in_secs"
  done
  log_err "Timeout while waiting for checkpoint creation"
  log_err "Script ended without removing savepoint"
  exit 1
}

validate_savepoint() {
  local savepoint_path
  savepoint_path=$(echo "$1" | sed 's!file://!!g')
  log_info "> Validating savepoint: <$savepoint_path>"
  if [ -d "$savepoint_path" ]; then
    if [ -f "$savepoint_path/_metadata" ]; then
      log_info "> Valid savepoint"
      return 0
    fi
  fi
  log_warn "> Invalid savepoint"
  return 1
}

remove_savepoint_ref(){
  local savepoint_ref_path
  savepoint_ref_path=$1
  log_info "> Removing savepoint reference file: <$savepoint_ref_path>"
  rm -f "$savepoint_ref_path"
}

entrypoint() {
  local default_zk_root zk_host env_zk_root_path zk_root_path
  missing_env_msg="ERROR: Could not find environment variable"
  zk_host="${FLINK_CONF_HIGH_AVAILABILITY_ZOOKEEPER_QUORUM:?$missing_env_msg}"

  default_zk_root="/flink"
  env_zk_root_path="$FLINK_CONF_HIGH_AVAILABILITY_ZOOKEEPER_PATH_ROOT"
  zk_root_path="${env_zk_root_path:-$default_zk_root}"

  local ha_zk_path ha_checkpoint_path
  local default_ha_chk default_ha_zk env_ha_chk_path env_ha_zk_path
  default_ha_chk="/mnt/$job_name-states/checkpoints"
  default_ha_zk="/mnt/$job_name-states/zookeeper"

  env_ha_chk_path=$(clean_protocol "$FLINK_CONF_STATE_CHECKPOINTS_DIR")
  ha_checkpoint_path="${env_ha_chk_path:-$default_ha_chk}"

  env_ha_zk_path=$(clean_protocol "$FLINK_CONF_HIGH_AVAILABILITY_STORAGEDIR")
  ha_zk_path="${env_ha_zk_path:-$default_ha_zk}"

  local rest_api_host rest_api_port rest_api_addr
  rest_api_host="${FLINK_CONF_JOBMANAGER_RPC_ADDRESS:?$missing_env_msg}"
  rest_api_port="${FLINK_CONF_REST_PORT:?$missing_env_msg}"
  rest_api_addr="http://${rest_api_host}:${rest_api_port}"


  local timeout_in_secs interval_in_secs
  timeout_in_secs="${COBLI_ENTRYPOINT_TIMEOUT_IN_SECS:-300}"
  interval_in_secs="${COBLI_ENTRYPOINT_INTERVAL_IN_SECS:-5}"

  log_info "Entrypoint running..."

  log_info "Ensuring that H.A. directories are present on EFS"
  ensure_ha_directories "$ha_savepoint_path" "$ha_checkpoint_path" \
    "$ha_zk_path"

  log_info "Looking for savepoints"
  savepoint=$(get_savepoint_ref "$savepoint_ref_path")

  if [ -z ${savepoint:+x} ]; then
    log_warn "Submiting job without savepoint"
    submit_job "$@"
  else
    log_info "Validating savepoint ref"
    if validate_savepoint "$savepoint"; then
      log_info "Cleaning up zookeeper data"
      clean_zookeeper_data "$zk_host" "$zk_root_path" "$job_name"

      log_info "Submiting job with savepoint"
      submit_job "$@" "--fromSavepoint $savepoint"

      log_info "Waiting for checkpoint completion"
      ensure_checkpoint_completion \
        "$rest_api_addr" \
        "$job_name" \
        "$timeout_in_secs" \
        "$interval_in_secs"
    else
      log_warn "Submiting job without savepoint"
      submit_job "$@"
    fi
    remove_savepoint_ref "$savepoint_ref_path"
  fi
  log_info "Entrypoint done"
  wait
}

entrypoint "$@"

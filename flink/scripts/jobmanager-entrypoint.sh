#! /bin/bash
set -e
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
red_color='\033[0;31m'
no_color='\033[0m'
yellow_color='\033[1;33m'

log_warn() {
  if [ $cobli_verbosity_level -ge 1 ]; then
    echo -e "${yellow_color}COBLI_ENTRYPOINT: $@${no_color}" 1>&2
  fi
}

log_err() {
  echo -e "${red_color}COBLI_ENTRYPOINT: $@${no_color}" 1>&2
}

submit_job() {
  log_warn "> Submiting job..."
  /opt/flink/bin/standalone-job.sh "$@" 1>&2 &
  log_warn "> Job submited"
}

ensure_ha_directories() {
  log_warn "> Ensuring directories existence..."
  mkdir -p $@
  log_warn "> Directories present"
}

get_savepoint_ref() {
  local savepoint_ref_path savepoint_path
  savepoint_ref_path="$1"
  savepoint_path=''
  if [ -f "$savepoint_ref_path" ]; then
    log_warn "> Savepoint reference file found"
    log_warn "> Geting savepoint path..."
    savepoint_path="$(cat $savepoint_ref_path | sed 's/#.*//g' )"
    log_warn "> Got savepoint: <$savepoint_path>"
  else
    log_warn "> Savepoint file not fount"
  fi
  echo $savepoint_path
}

clean_zookeeper_data() {
  local zk_host zk_root_path job_name
  zk_host="$1"
  zk_root_path="$2"
  job_name="$3"

  local zk_clean_cmd
  zk_clean_cmd="rmr $zk_root_path/$job_name"

  local zk_cp_0 zk_cp_1 zk_cp_2 zk_cp
  zk_cp_0="lib/org.apache.zookeeper.zookeeper-3.4.13.jar"
  zk_cp_1="lib/org.slf4j.slf4j-api-1.7.26.jar"
  zk_cp_2="org.apache.zookeeper.ZooKeeperMain"
  zk_cp="$zk_cp_0:$zk_cp_1 $zk_cp_2"

  log_warn "> Cleaning zookeeper path: <$zk_root_path/$job_name>"

  echo "$zk_clean_cmd" | java -cp $zk_cp -server $zk_host

  log_warn "> Zookeeper cleaned"
}

query_jobmanager_api_for_checkpoints() {
  log_warn "> Querying rest api for checkpoints completed"
  local rest_api_addr job_id api_response
  rest_api_addr="$1"
  # TODO get job id from rest api"
  job_id="00000000000000000000000000000000"
  api_response=$(curl -s "$rest_api_addr/jobs/$job_id/checkpoints" || true)
  log_warn "> Api response: <$api_response>"
  echo $api_response
}

get_number_of_checkpoints_completed() {
  log_warn "> Getting API response"
  local api_response jq_path rest_api_addr
  rest_api_addr="$1"
  api_response="$(query_jobmanager_api_for_checkpoints $rest_api_addr)"
  jq_path=".counts.completed"
  num_checkpoint_completed="$(echo $api_response | jq $jq_path )"
  log_warn "> Num of checkpoints completed: <$num_checkpoint_completed>"
  echo $num_checkpoint_completed
}

ensure_checkpoint_completion() {
  local rest_api_addr job_name timout interval_in_secs
  rest_api_addr="$1"
  job_name="$2"
  timeout_in_secs="$3"
  interval_in_secs="$4"

  local current_time end_time
  current_time=$(TZ=UTC0 date "+%s")
  end_time=$(( $current_time + $timeout_in_secs ))

  local num_checkpoint_completed
  while [ $current_time -lt $end_time ]; do
    current_time="$(TZ=UTC0 date '+%s')"
    log_warn "> Verifying checkpoint creation..."

    num_checkpoint_completed="$(get_number_of_checkpoints_completed \
      $rest_api_addr)"
    if [[ ${num_checkpoint_completed:+x} && $num_checkpoint_completed -gt 0 ]];
    then
      log_warn "> Cleaning up savepoint reference"
      return
    fi
    sleep $interval_in_secs
  done
  log_err "ERROR: Timeout while wayting for checkpoint creation"
  log_err "ERROR: Termination script whitou removing savepoint"
  exit 1
}

validate_savepoint() {
  local savepoint_path
  savepoint_path="$(echo $1 | sed 's!file://!!g')"
  log_warn "> Validating savepoint: <$savepoint_path>"
  if [ -d "$savepoint_path" ]; then
    if [ -f "$savepoint_path/_metadata" ]; then
      log_warn "> Valid savepoint"
      return 0
    fi
  fi
  log_warn "> Invalid savepoint"
  return 1
}

remove_savepoint_ref(){
  local savepoint_ref_path
  savepoint_ref_path=$1
  log_warn "> Removing savepoint reference file: <$savepoint_ref_path>"
  rm -f "$savepoint_ref_path"
}


entrypoint() {
  local default_zk_root zk_host zk_root_path job_name
  missing_env_msg="ERROR: Could not find environment variable"
  zk_host="${COBLI_FLINK_ZK_HOST:?$missing_env_msg}"
  job_name="${COBLI_FLINK_JOB_NAME:?$missing_env_msg}"

  default_zk_root="/flink"
  zk_root_path="${COBLI_FLINK_ZK_ROOT:-$default_zk_root}"

  local ha_savepoint_path ha_zk_path ha_checkpoint_path
  local default_ha_sp default_ha_chk default_ha_zk
  default_ha_sp="/mnt/$job_name-states/savepoints"
  default_ha_chk="/mnt/$job_name-states/checkpoints"
  default_ha_zk="/mnt/$job_name-states/zookeeper"

  ha_savepoint_path="${COBLI_FLINK_HA_SAVEPOINT_PATH:-$default_ha_sp}"
  ha_checkpoint_path="${COBLI_FLINK_HA_CHECKPOINT_PATH:-$default_ha_chk}"
  ha_zk_path="${COBLI_FLINK_HA_ZK_PATH:-$default_ha_zk}"

  local default_sp_ref savepoint_ref_path
  default_sp_ref="${ha_savepoint_path}/last_savepoint.cobli"
  savepoint_ref_path="${COBLI_FLINK_SAVEPOINT_REF_PATH:-$default_sp_ref}"

  local rest_api_addr
  rest_api_addr="${COBLI_FLINK_REST_API_ADDR:?$missing_env_msg}"


  local timeout_in_secs interval_in_secs
  timeout_in_secs="${COBLI_ENTRYPOINT_TIMEOUT_IN_SECS:-300}"
  interval_in_secs="${COBLI_ENTRYPOINT_INTERVAL_IN_SECS:-5}"

  log_warn "Entrypoint running..."

  log_warn "Ensuring that H.A. directories are present on EFS"
  ensure_ha_directories "$ha_savepoint_path" "$ha_checkpoint_path" \
    "$ha_zk_path"

  log_warn "Looking for savepoints"
  savepoint="$(get_savepoint_ref $savepoint_ref_path)"

  if [ -z ${savepoint:+x} ]; then
    log_warn "Submiting job without savepoint"
    submit_job $@
  else
    log_warn "Validating savepoint ref"
    if $(validate_savepoint $savepoint); then
      log_warn "Cleaning up zookeeper data"
      clean_zookeeper_data "$zk_host" "$zk_root_path" "$job_name"

      log_warn "Submiting job with savepoint"
      submit_job $@ "--fromSavepoint $savepoint"

      log_warn "Waiting for checkpoint completion"
      ensure_checkpoint_completion \
        $rest_api_addr \
        $job_name \
        $timeout_in_secs \
        $interval_in_secs
    else
      log_warn "Submiting job without savepoint"
      submit_job $@
    fi
    remove_savepoint_ref "$savepoint_ref_path"
  fi
  log_warn "Entrypoint done"
  wait
}

entrypoint $@

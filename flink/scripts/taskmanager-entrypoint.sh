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

cobli_verbosity_level=${COBLI_FLINK_VERBOSITY_LEVEL:-0}

cobli_script="COBLI_ENTRYPOINT"

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common.sh

entrypoint() {
  log_warn "Entrypoint running..."
  ensure_flink_config
  log_warn "Starting taskmanager..."
  "$flink_home/bin/taskmanager.sh" "$@" 1>&2 &
  log_warn "Entrypoint done"
  wait
}

entrypoint "$@"

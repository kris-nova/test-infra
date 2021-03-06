#!/bin/bash
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

readonly testinfra="$(dirname "${0}")/.."

### provider-env
export KUBERNETES_PROVIDER="gce"
export E2E_MIN_STARTUP_PODS="1"
export KUBE_GCE_ZONE="us-central1-f"
export FAIL_ON_GCP_RESOURCE_LEAK="true"
export CLOUDSDK_CORE_PRINT_UNHANDLED_TRACEBACKS="1"

### project-env
# expected empty

### job-env
export ENABLE_GARBAGE_COLLECTOR="true"
export E2E_NAME="kubemark-100pods"
export PROJECT="k8s-jenkins-kubemark"
export E2E_TEST="false"
export USE_KUBEMARK="true"
export KUBEMARK_TESTS="\[Feature:HighDensityPerformance\]"
export KUBEMARK_TEST_ARGS="--gather-resource-usage=true --garbage-collector-enabled=true"
export FAIL_ON_GCP_RESOURCE_LEAK="false"
# Override defaults to be independent from GCE defaults and set kubemark parameters
export NUM_NODES="8"
export MASTER_SIZE="n1-standard-2"
export NODE_SIZE="n1-standard-8"
export KUBEMARK_MASTER_SIZE="n1-standard-32"
export KUBEMARK_NUM_NODES="600"

# The kubemark scripts build a Docker image
export JENKINS_ENABLE_DOCKER_IN_DOCKER="y"
export KUBE_NODE_OS_DISTRIBUTION="gci"

# TODO: remove after we stabilize performance of this suite.
export KUBEMARK_MASTER_ROOT_DISK_SIZE="100GB"
export MASTER_DISK_SIZE="100GB"
export SCHEDULER_TEST_ARGS="--v=4"

### post-env

# Assume we're upping, testing, and downing a cluster
export E2E_UP="${E2E_UP:-true}"
export E2E_TEST="${E2E_TEST:-true}"
export E2E_DOWN="${E2E_DOWN:-true}"

# Skip gcloud update checking
export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true
# Use default component update behavior
export CLOUDSDK_EXPERIMENTAL_FAST_COMPONENT_UPDATE=false

# AWS variables
export KUBE_AWS_INSTANCE_PREFIX="${E2E_NAME}"

# GCE variables
export INSTANCE_PREFIX="${E2E_NAME}"
export KUBE_GCE_NETWORK="${E2E_NAME}"
export KUBE_GCE_INSTANCE_PREFIX="${E2E_NAME}"

# GKE variables
export CLUSTER_NAME="${E2E_NAME}"
export KUBE_GKE_NETWORK="${E2E_NAME}"

# Get golang into our PATH so we can run e2e.go
export PATH="${PATH}:/usr/local/go/bin"

### Runner
readonly runner="${testinfra}/jenkins/dockerized-e2e-runner.sh"
timeout -k 15m 160m "${runner}" && rc=$? || rc=$?

### Reporting
if [[ ${rc} -eq 124 || ${rc} -eq 137 ]]; then
    echo "Build timed out" >&2
elif [[ ${rc} -ne 0 ]]; then
    echo "Build failed" >&2
fi
echo "Exiting with code: ${rc}"
exit ${rc}

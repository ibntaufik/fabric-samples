#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
# test network home var targets to test-network folder
# the reason we use a var here is to accommodate scenarios
# where execution occurs from folders outside of default as $PWD, such as the test-network/addOrg3 folder.
# For setting environment variables, simple relative paths like ".." could lead to unintended references
# due to how they interact with FABRIC_CFG_PATH. It's advised to specify paths more explicitly,
# such as using "../${PWD}", to ensure that Fabric's environment variables are pointing to the correct paths.
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
. ${TEST_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/varion.com/tlsca/tlsca.varion.com-cert.pem
export PEER0_FARMER_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/farmer.varion.com/tlsca/tlsca.farmer.varion.com-cert.pem
export PEER0_PULPER_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/pulper.varion.com/tlsca/tlsca.pulper.varion.com-cert.pem
export PEER0_HULLER_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/huller.varion.com/tlsca/tlsca.huller.varion.com-cert.pem
export PEER0_EXPORT_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/export.varion.com/tlsca/tlsca.export.varion.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG == "farmer" ]; then
    export CORE_PEER_LOCALMSPID=FarmerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_FARMER_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/farmer.varion.com/users/Admin@farmer.varion.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG == "pulper" ]; then
    export CORE_PEER_LOCALMSPID=PulperMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_PULPER_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/pulper.varion.com/users/Admin@pulper.varion.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
  elif [ $USING_ORG == "huller" ]; then
    export CORE_PEER_LOCALMSPID=HullerMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HULLER_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/huller.varion.com/users/Admin@huller.varion.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG == "export" ]; then
    export CORE_PEER_LOCALMSPID=ExportMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_EXPORT_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/export.varion.com/users/Admin@export.varion.com/msp
    export CORE_PEER_ADDRESS=localhost:10051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
    	PEERS="$PEER"
    else
	    PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    if [ $1 == "farmer" ]; then
      CA=PEER0_FARMER_CA
    elif [ $1 == "pulper" ]; then
      CA=PEER0_PULPER_CA
    elif [ $1 == "huller" ]; then
      CA=PEER0_HULLER_CA
    elif [ $1 == "export" ]; then
      CA=PEER0_EXPORT_CA
    fi
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

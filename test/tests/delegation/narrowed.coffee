import assert from "assert"
import { clone } from "@dashkite/joy"

import { toJSON } from "../../../src/utils"

import keyStore from "../../key-store"

import { confidential as Confidential } from "panda-confidential"
import Capability from "../../../src"

confidential = Confidential()
{SignatureKeyPair, PrivateKey} = confidential
{issue, bundle, lookup, exercise, parse, verify, delegate,
  Directory, Contract} = Capability confidential

Test = ->
  # The API has its own signature key pair for issuing capabilites to people
  APIKeyPair = SignatureKeyPair.from "base64", keyStore.issuer.main

  # Alice and Bob create their profile signing key pairs.
  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]

  Bob =  SignatureKeyPair.from "base64", keyStore.bob.devices[0]


  #==========================================

  # API creates a profile for Alice and issues grants for her resources.
  expiration = do ->
    d = new Date()
    d.setMinutes d.getMinutes() + 2
    d.toISOString()

  directory = bundle [
    issue APIKeyPair,
      template: "/profiles/alice/dashes"
      methods: ["POST"]
      tolerance:
        seconds: 5
      expires: expiration
      issuer:
        url: "http://localhost:8000/issuer/main"
      claimant:
        template: "http://localhost:8000/alice/{device}"

    issue APIKeyPair,
      template: "/profiles/alice/dashes/{id}"
      methods: ["GET", "PUT"]
      tolerance:
        seconds: 5
      expires: expiration
      issuer:
        url: "http://localhost:8000/issuer/main"
      claimant:
        template: "http://localhost:8000/alice/{device}"
  ]

  #======================================

  # Later, when the alice wants delegate authority to *only read* dash with an  *id of 12345*, she uses a contract to issue a narrow delegation of her grant.

  contract = directory["/profiles/alice/dashes/{id}"]["PUT"]

  # alice specifies the URL parameters for the request she's delegating permission to perform.
  parameters = id: "12345"

  # alice signs a delegation to give bob authority, and hands it off to bob.
  contract = delegate Alice, contract,
    template: parameters
    methods: ["GET"]
    claimant:
      template:
        device: "device0"
    delegate:
      template: "http://localhost:8000/bob/{device}"


  #=====================================

  # bob forms a claim against the delegated contract and its constraints to exercise the grant.
  contract = exercise Bob, contract,
    method: "GET"
    claimant:
      template:
        device: "device0"  # This is bob's device0, not alice's

  # The contract is ready to be serialized and placed into the Authorization header.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "GET"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  #=======================================


  # Back over in the API, it recieves the request from bob
  try
    # API verifies the request's claim
    contract = parse request
    await verify request, contract
  catch e
    console.error e
    assert.fail "verification should have passed."

  #========================================
  # Revocation Check

  # Panda-capability confirms the consistency of a contract and its components. When using Web signatures, panda-capability issues HTTP requests to confirm the key value as part of the verify flow.


export default Test

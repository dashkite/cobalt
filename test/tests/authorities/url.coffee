import assert from "assert"
import { clone } from "@dashkite/joy"

import { toJSON } from "../../../src/utils"

import keyStore from "../../key-store"

import { confidential as Confidential } from "panda-confidential"
import Capability from "../../../src"

confidential = Confidential()
{SignatureKeyPair, PrivateKey} = confidential
{issue, bundle, lookup, exercise, parse, verify,
  Directory, Contract} = Capability confidential

Test = ->
  # The API has its own signature key pair for issuing capabilites to people
  APIKeyPair = SignatureKeyPair.from "base64", keyStore.issuer.main

  # Alice creates her profile signing key pair.
  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]


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
        url: "http://localhost:8000/alice/device0"

    issue APIKeyPair,
      template: "/profiles/alice/dashes/{id}"
      methods: ["GET", "PUT"]
      tolerance:
        seconds: 5
      expires: expiration
      issuer:
        url: "http://localhost:8000/issuer/main"
      claimant:
        url: "http://localhost:8000/alice/device0"
  ]

  # API serializes the directory for transport to alice.
  serializedDirectory = directory.to "utf8"


  #======================================

  # Later, when the alice wants to excercise one of the contracts in
  # her directory by editing an existing dash.

  # alice hydrates her directory from serialized storage
  directory = Directory.from "utf8", serializedDirectory

  # alice specifies the URL parameters for the request.
  parameters = id: "12345"

  # alice looks up the relevant contract matching the capability she wants
  # to exercise. (URL could come from panda-sky-client)
  methods = lookup directory, "/profiles/alice/dashes/12345", parameters
  contract = methods.PUT

  assert contract?, "lookup failed"
  assert (Contract.isType contract), "lookup failed"

  # alice forms a claim against the contract and its constraints to exercise the grant.
  contract = exercise Alice, contract,
    template: parameters
    method: "PUT"
    claimant:
      url: "http://localhost:8000/alice/device0"

  # The contract is ready to be serialized and placed into the Authorization header.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  #=======================================


  # Back over in the API, it recieves the request from alice
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

import assert from "assert"
import { clone } from "@dashkite/joy"

import { toJSON } from "../../../src/utils"

import { confidential as Confidential } from "panda-confidential"
import Capability from "../../../src"

confidential = Confidential()
{SignatureKeyPair, PrivateKey} = confidential
{issue, bundle, lookup, exercise, parse, verify,
  Directory, Contract} = Capability confidential

Test = ->
  
  # The API has its own signature key pair for issuing capabilites to people
  APIKeyPair = await SignatureKeyPair.create()

  # Alice creates her profile signing key pair.
  Alice = await SignatureKeyPair.create()

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
        literal: APIKeyPair.publicKey.to "base64"
      claimant:
        literal: Alice.publicKey.to "base64"

    issue APIKeyPair,
      template: "/profiles/alice/dashes/{id}"
      methods: ["GET", "PUT"]
      tolerance:
        seconds: 5
      expires: expiration
      issuer:
        literal: APIKeyPair.publicKey.to "base64"
      claimant:
        literal: Alice.publicKey.to "base64"
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
      literal: Alice.publicKey.to "base64"

  # The contract is ready to be serialized and placed into the Authorization header.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  # Alternate request with different cased authorization scheme name.
  request2 = clone request
  request2.headers.authorization = "capability #{contract.to "base64"}"


  #=======================================


  # Back over in the API, it recieves the request from alice
  try
    # API verifies the request's claim
    contract = parse request
    parse request2  # case insenstivity check
    await verify request, contract
  catch e
    console.error e
    assert.fail "verification should have passed."

  #========================================
  # Revocation Check

  # Panda-capability confirms the consistency of a contract and its components. When using Web signatures, panda-capability issues HTTP requests to confirm the key value as part of the verify flow.

  # However, in this case we only dealt with Authority literals.  So, a validator would need to compare the keys idependently with some authoritative source if there is reason to suspect the issuer or claimant keys have been revoked since issuance.

export default Test

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

  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]
  Bob = SignatureKeyPair.from "base64", keyStore.bob.devices[0]


  #==========================================

  # API creates a profile for Alice and issues grants for her resources.
  expiration = do ->
    d = new Date()
    d.setMinutes d.getMinutes() + 2
    d.toISOString()

  directory = bundle [
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

  #======================================

  _contract = directory["/profiles/alice/dashes/{id}"]["PUT"]

  # URL parameters for the request.
  parameters = id: "12345"


  #======================================
  # Forged device

  contract = exercise Bob, _contract,
    template: parameters
    method: "PUT"
    claimant:
      url: "http://localhost:8000/alice/device0"

  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?

  #=======================================
  # Forged method

  contract = exercise Alice, _contract,
    template: parameters
    method: "POST"
    claimant:
      url: "http://localhost:8000/alice/device0"

  request =
    url: "/profiles/alice/dashes/12345"
    method: "POST"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?

  #=======================================



export default Test

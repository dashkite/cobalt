import assert from "assert"
import { sleep } from "@dashkite/joy"
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

  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]
  Bob = SignatureKeyPair.from "base64", keyStore.bob.devices[0]


  #==========================================
  # URL parameters for the request.
  parameters = id: "12345"


  #======================================
  # Replay beyond grant expiration.

  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: do ->
      d = new Date()
      d.setSeconds d.getSeconds() + 1
      d.toISOString()
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = exercise Alice, contract,
    template: parameters
    method: "PUT"
    claimant:
      url: "http://localhost:8000/alice/device0"

  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  try
    await sleep 2000
    await verify request, contract
    assert.fail "verification should fail."
  catch




  #=======================================
  # Replay beyond delegation expiration.

  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 10
    expires: do ->
      d = new Date()
      d.setSeconds d.getSeconds() + 60
      d.toISOString()
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"


  contract = delegate Alice, contract,
    template: parameters
    methods: ["PUT"]
    expires: do ->
      d = new Date()
      d.setSeconds d.getSeconds() + 1
      d.toISOString()
    claimant:
      url: "http://localhost:8000/alice/device0"
    delegate:
      url: "http://localhost:8000/bob/device0"

  contract = exercise Bob, contract,
    method: "PUT"
    claimant:
      url: "http://localhost:8000/bob/device0"

  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await sleep 2000
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?



  #======================================
  # Replay beyond grant tolerance.

  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 1
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = exercise Alice, contract,
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
    await sleep 2000
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?



export default Test

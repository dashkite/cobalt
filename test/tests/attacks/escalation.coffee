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

  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]
  Bob = SignatureKeyPair.from "base64", keyStore.bob.devices[0]


  #==========================================

  # API creates a profile for Alice and issues grants for her resources.
  expiration = do ->
    d = new Date()
    d.setMinutes d.getMinutes() + 2
    d.toISOString()

  contract = issue APIKeyPair,
      template: "/profiles/alice/dashes/{id}"
      methods: ["GET", "PUT"]
      tolerance:
        seconds: 5
      expires: expiration
      issuer:
        url: "http://localhost:8000/issuer/main"
      claimant:
        url: "http://localhost:8000/alice/device0"

  # URL parameters for the request.
  parameters = id: "12345"


  #======================================
  # Escalating grant scope

  contract = exercise Alice, contract,
    template: parameters
    method: "PUT"
    claimant:
      url: "http://localhost:8000/alice/device0"

  request =
    url: "/profiles/bob/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?


  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: expiration
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
    url: "/profiles/bob/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?




  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: expiration
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = exercise Alice, contract,
    template: parameters
    method: "DELETE"
    claimant:
      url: "http://localhost:8000/alice/device0"

  request =
    url: "/profiles/alice/dashes/12345"
    method: "DELETE"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?


  #=======================================
  # Escalating delegation scope
  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: expiration
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = delegate Alice, contract,
    template: parameters
    methods: ["PUT"]
    claimant:
      url: "http://localhost:8000/alice/device1"
    delegate:
      template: "http://localhost:8000/bob/{device}"

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
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?


  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: expiration
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = delegate Alice, contract,
    template: parameters
    methods: ["PUT"]
    claimant:
      url: "http://localhost:8000/alice/device0"
    delegate:
      template: "http://localhost:8000/bob/device1"

  contract = exercise Bob, contract,
    method: "PUT"
    claimant:
      url: "http://localhost:8000/bob/device1"


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



  contract = issue APIKeyPair,
    template: "/profiles/alice/dashes/{id}"
    methods: ["GET", "PUT"]
    tolerance:
      seconds: 5
    expires: expiration
    issuer:
      url: "http://localhost:8000/issuer/main"
    claimant:
      url: "http://localhost:8000/alice/device0"

  contract = delegate Alice, contract,
    template: parameters
    methods: ["PUT"]
    claimant:
      url: "http://localhost:8000/alice/device0"
    delegate:
      template: "http://localhost:8000/bob/device0"

  contract = exercise Bob, contract,
    method: "DELETE"
    claimant:
      url: "http://localhost:8000/bob/device0"


  request =
    url: "/profiles/alice/dashes/12345"
    method: "DELETE"
    headers:
      authorization: "Capability #{contract.to "base64"}"

  error = null
  try
    await verify request, contract
  catch error
  assert.fail "verification should fail." unless error?

  #=======================================



export default Test

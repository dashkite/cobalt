import assert from "assert"
import { sleep } from "@dashkite/joy"
import { toJSON } from "../../../src/utils"

import keyStore from "../../key-store"

import { confidential as Confidential } from "panda-confidential"
import Capability from "../../../src"

confidential = Confidential()
{SignatureKeyPair, PrivateKey, randomBytes, convert} = confidential
{issue, bundle, lookup, exercise, parse, verify, memoize,
  Directory, Contract} = Capability confidential

Test = ->
  # The API has its own signature key pair for issuing capabilites to people
  APIKeyPair = SignatureKeyPair.from "base64", keyStore.issuer.main

  # Alice creates her profile signing key pair.
  Alice = SignatureKeyPair.from "base64", keyStore.alice.devices[0]
  secret = convert from: "bytes", to: "base64", await randomBytes 16

  #==========================================

  # API creates a profile for Alice and issues grants for her resources.
  expiration = do ->
    d = new Date()
    d.setMinutes d.getMinutes() + 2
    d.toISOString()


  memo = memoize secret,
    resource:
      url: "/profiles/alice/dashes/12345"
    methods: ["PUT"]
    expires: expiration

  # Since there is no URL template, the memo can be used directly.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Memo #{memo.to "base64"}"

  try
    # API verifies the request's claim
    memo = parse request
    await verify request, memo, secret
  catch e
    console.error e
    assert.fail "verification should have passed."




  #========================================
  # Memo with claim URL template parameters
  memo = memoize secret,
    resource:
      template: "/profiles/alice/dashes/{id}"
    methods: ["PUT"]
    expires: expiration

  # Use exercise to claim with URL template values.
  memo = exercise memo,
    template:
      id: "12345"

  # Since there is no URL template, the memo can be used directly.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Memo #{memo.to "base64"}"

  try
    # API verifies the request's claim
    memo = parse request
    await verify request, memo, secret
  catch e
    console.error e
    assert.fail "verification should have passed."




  #=========================================
  # Memos expire

  expiration = do ->
    d = new Date()
    d.setSeconds d.getSeconds() + 1
    d.toISOString()

  memo = memoize secret,
    resource:
      url: "/profiles/alice/dashes/12345"
    methods: ["PUT"]
    expires: expiration

  # Since there is no URL template, the memo can be used directly.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Memo #{memo.to "base64"}"

  try
    await sleep 2000
    memo = parse request
    await verify request, memo, secret
    assert.fail "verification should have failed."
  catch

export default Test

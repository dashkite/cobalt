import assert from "assert"
import {toJSON, clone} from "panda-parchment"

import keyStore from "../../key-store"

import {confidential as Confidential} from "panda-confidential"
import Capability from "../../../src"
import Helpers from "../../helpers"

confidential = Confidential()
{SignatureKeyPair, PrivateKey} = confidential
{issue, bundle, lookup, exercise, parse, verify, delegate,
  Directory, Contract} = Capability confidential

{addRevocationKey, removeRevocationKey} = Helpers confidential

Test = ->
  # The API has its own signature key pair for issuing capabilites to people
  APIKeyPair = SignatureKeyPair.from "base64", keyStore.issuer.main

  # We create an authority for alice that we can revoke at will.
  Alice = await addRevocationKey()
  aliceName = Alice.publicKey.to "safe-base64"


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
        url: "http://localhost:8000/revocation/#{aliceName}"
  ]

  #======================================

  contract = directory["/profiles/alice/dashes/{id}"]["PUT"]

  # alice specifies the URL parameters for the request.
  parameters = id: "12345"

  # alice forms a claim against the contract and its constraints to exercise the grant.
  contract = exercise Alice, contract,
    template: parameters
    method: "PUT"
    claimant:
      template:
        device: "device0"

  # The contract is ready to be serialized and placed into the Authorization header.
  request =
    url: "/profiles/alice/dashes/12345"
    method: "PUT"
    headers:
      authorization: "Capability #{contract.to "base64"}"
      date: new Date().toISOString()  # added by Fetch agent automatically.

  #=======================================


  # Back over in the API, it recieves the request from alice
  try
    # API verifies the request's claim
    contract = parse request
    await verify request, contract
  catch e
    console.error e
    assert.fail "verification should have passed."

  #=======================================
  # Now we revoke the claimant (alice's) key...
  await removeRevocationKey aliceName

  # ...and attempt another verification
  try
    # API verifies the request's claim
    await verify request, contract
    assert.fail "verification should have failed."
  catch





export default Test

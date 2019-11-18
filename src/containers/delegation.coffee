import {isType, toJSON} from "panda-parchment"
import AJV from "ajv"
import schema from "../schema/delegation"

ajv = new AJV()

Container = (library, confidential) ->
  {Declaration, verify, Message, hash} = confidential

  class Delegation
    constructor: (@declaration) ->
      @validate()
      @signatories = @declaration.signatories.list "base64"

      {@message} = @declaration
      {@template, @methods,
        @integrity, @expires,
        @claimant, @revocations=[], @delegate} = @message.json()

    to: (hint) -> @declaration.to hint

    verify: -> verify @declaration

    # Compares the contents to a schema.
    validate: ->
      unless Declaration.isType @declaration
        throw new Error "Delegation must be a signature declaration"

      unless ajv.validate schema, @declaration.message.json()
        console.error toJSON ajv.errors, true
        throw new Error "Unable to create delegation: failed validation."

    @create: (value) -> new Delegation value

    @from: (hint, value) -> new Delegation Declaration.from hint, value

    @integrityHash: ({grant, delegations}) ->
      hash Message.from "utf8", toJSON
        grant: grant.to "utf8"
        delegations: (d.to "utf8" for d in delegations)
      .to "base64"

    @isType: isType @
    @areType: areType @

export default Container

import {isType, areType, toJSON} from "panda-parchment"

Container = (library, confidential) ->
  {ajv, schema} = library
  {Declaration, verify, Message, hash} = confidential

  class Delegation
    constructor: (@declaration) ->
      @validate()
      @signatories = @declaration.signatories.list "base64"

      {@template, @methods,
        @integrity, @expires, @embargo,
        @claimant, @revocations=[], @delegate} = @declaration.message.json()

    to: (hint) -> @declaration.to hint

    verify: -> verify @declaration

    # Compares the contents to a schema.
    validate: ->
      unless Declaration.isType @declaration
        throw new Error "Delegation must be a signature declaration"

      if ajv?
        unless ajv.validate schema.delegation, @declaration.message.json()
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

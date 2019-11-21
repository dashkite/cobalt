import {isType, areType} from "panda-parchment"
import AJV from "ajv"
import schema from "../schema/claim"

ajv = new AJV()

assert = (predicate, message) ->
  throw new Error "verify failure: #{message}" unless predicate

Container = (library, confidential) ->
  {verify, Declaration} = confidential

  class Claim
    constructor: (@declaration) ->
      @validate()
      @signatories = @declaration.signatories.list "base64"

      {@template, @method,
        @timestamp,
        @claimant} = @declaration.message.json()

    to: (hint) -> @declaration.to hint

    verify: -> verify @declaration

    # Compares the contents to a schema.
    validate: ->
      unless Declaration.isType @declaration
        throw new Error "Claim must be a signature declaration"

      unless ajv.validate schema, @declaration.message.json()
        console.error toJSON ajv.errors, true
        throw new Error "Unable to create claim: failed validation."


    @create: (value) -> new Claim value

    @from: (hint, value) -> new Claim Declaration.from hint, value

    @isType: isType @
    @areType: areType @

export default Container

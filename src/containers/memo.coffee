import {isType, areType, fromJSON, toJSON, merge} from "panda-parchment"

Container = (library, confidential) ->
  {ajv, schema} = library
  {Message, hash, convert} = confidential

  class Memo
    constructor: ({@integrity, @content, @claim}) ->
      @validate()

    to: (hint) ->
      memo = {@integrity, @content, @claim}
      if hint == "utf8"
        toJSON memo
      else
        convert from: "utf8", to: hint, toJSON memo

    # Verifies the integrity of the memo, given the anchoring secret.
    verify: (secret) ->
      claim = hash Message.from "utf8", toJSON merge {secret}, @content
      .to "base64"

      unless claim == @integrity
        throw new Error "Invalid memo. Integrity hash failure."

    # Compares the memo's contents to a schema.
    validate: ->
      if ajv?
        unless ajv.validate schema.memo, {@integrity, @content, @claim}
          console.error toJSON ajv.errors, true
          throw new Error "Unable to create memo: failed validation."

    @create: (value) -> new Memo value

    @from: (hint, value) ->
      new Memo do ->
        if hint == "utf8"
          fromJSON value
        else
          fromJSON convert from: hint, to: "utf8", value

    @isType: isType @
    @areType: areType @

export default Container

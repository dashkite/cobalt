import { isString, isObject } from "@dashkite/joy/type"
import { merge } from "@dashkite/joy/object"
import { generic } from "@dashkite/joy/generic"
import { toJSON } from "../utils"

Memoize = (library, confidential) ->
  {Memo} = library
  {Message, hash} = confidential

  memoize = generic

    name: "memoize"
    description: "Issues a Memo to a claimant in place of a grant to be more performantly validated."

  generic memoize,
    isString, isObject,
    (secret, content) ->

      # Link the content to an issuer-held secret with an integrity hash
      integrity = hash Message.from "utf8", toJSON merge {secret}, content
      .to "base64"

      # Issue memo
      Memo.create {integrity, content}

  memoize

export default Memoize

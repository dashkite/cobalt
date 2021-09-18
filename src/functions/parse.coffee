import { isString } from "@dashkite/joy/type"

assert = (predicate, message) ->
  throw new Error "authorization parse failure: #{message}" unless predicate

Parse = (library, confidential) ->
  {Contract, Memo} = library

  (request) ->
    header = request?.headers?.authorization
    assert header?, "unable to locate authorization header"
    assert (isString header), "header value must be a string"

    start = header.indexOf " "
    scheme = header[0...start]

    if scheme.match /[cC][aA][pP][aA][bB][iI][lL][iI][tT][yY]/
      Contract.from "base64", header[start...].trim()
    else if scheme.match /[mM][eE][mM][oO]/
      Memo.from "base64", header[start...].trim()
    else
      throw new Error "unable to match on authorization scheme header."

export default Parse

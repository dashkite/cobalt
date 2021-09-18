import { isString, isObject } from "@dashkite/joy/type"
import { generic } from "@dashkite/joy/generic"
import { URLTemplate } from "../utils"

Lookup = (library, confidential) ->
  {Directory} = library

  lookup = generic

    name: "lookup"
    description: "Lookup a Contract whose template matches the given URL."

  generic lookup, Directory.isType, isString, isObject,
    (directory, path, description) ->
      for template, methods of directory
        if path == URLTemplate.parse(template).expand(description)
          return methods
      undefined

  generic lookup, Directory.isType, isString,
    (directory, path) ->
      lookup directory, path, {}

  lookup

export default Lookup

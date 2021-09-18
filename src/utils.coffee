import { curry } from "@dashkite/joy/function"
import { isType, isString, isArray } from "@dashkite/joy/type"
import { isEmpty } from "@dashkite/joy/value"
import _URLTemplate from "es6-url-template"

allAllowedMethods = (methods) ->
  return false unless isArray methods
  return false if isEmpty methods
  return false for method in methods when !(method in allowedMethods)
  true

isUse = (use) ->
  return false unless isArray use
  return false if isEmpty use
  return false for item in use when !(isString item)
  true

fromJSON = (json) -> JSON.parse json
toJSON = (value) -> JSON.stringify value

# Apply isType to a collection.
areType = curry (type, array) ->
  return false unless isArray array
  for item in array
    return false unless isType type, item
  true

URLTemplate =
  parse: (template) -> new _URLTemplate template

export {
  isUse
  allAllowedMethods
  fromJSON
  toJSON
  areType
  URLTemplate
}

import { isType } from "@dashkite/joy/type"
import { assign as include, values } from "@dashkite/joy/object"
import { toJSON, fromJSON, areType } from "../utils"

Container = (library, confidential) ->
  {Contract} = library
  {convert} = confidential

  class Directory
    constructor: (directory) ->
      include @, directory
      @validate()

    to: (hint) ->
      directory = {}
      for template, methods of @
        directory[template] = {}
        for method, contract of methods
          directory[template][method] = contract.to "utf8"

      if hint == "utf8"
        toJSON directory
      else
        convert from: "utf8", to: hint, toJSON directory

    validate: ->
      for template, methods of @
        unless Contract.areType values methods
          throw new Error "Invalid directory: contract failed validation."

    @create: (value) -> new Directory value

    @from: (hint, value) ->
      new Directory do ->
        directory = do ->
          if hint == "utf8"
            fromJSON value
          else
            fromJSON convert from: hint, to: "utf8", value

        for template, methods of directory
          for method, contract of methods
            directory[template][method] = Contract.from "utf8", contract

        directory

    @isType: isType @
    @areType: areType @

export default Container

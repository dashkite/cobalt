import { generic } from "@dashkite/joy/generic"

Bundle = (library, confidential) ->

  {Directory, Contract} = library

  bundle = generic

    name: "bundle"
    description: "Bundles and array of Contracts into a Directory, with duplicates for each method on a given resource."

  generic bundle, Contract.areType, (contracts) ->

    directory = {}

    for contract in contracts
      {template, methods} = contract.grant

      directory[template] = {}

      for method in methods
        directory[template][method] = Contract.create contract

    Directory.create directory

  bundle

export default Bundle

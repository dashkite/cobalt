import { isObject } from "@dashkite/joy/type"
import { isEmpty } from "@dashkite/joy/value"
import { last } from "@dashkite/joy/array"
import { generic } from "@dashkite/joy/generic"
import { toJSON } from "../utils"

Delegate = (library, confidential) ->
  {Delegation, Contract} = library
  {SignatureKeyPair, sign, Message, hash} = confidential

  delegate = generic
    name: "delegate"
    description: "Delegates a given Grant to a third party claimant."

  generic delegate,
    SignatureKeyPair.isType, Contract.isType, isObject,
    (claimantKeyPair, contract, delegation) ->

      contract = Contract.create contract

      delegation.integrity = Delegation.integrityHash contract

      # Check delegation resource scope.
      if delegation.template?
        for d in contract.delegations
          if d.template?
            throw new Error "Cannot rebind grant URL template."

      # Check delegation method scope.
      if isEmpty contract.delegations
        referenceMethods = contract.grant.methods
      else
        referenceMethods = (last contract.delegations).methods

      for method in delegation.methods
        unless method in referenceMethods
          throw new Error "Delegatation method is beyond granted scope."

      # Add a claim to the contract including the claimant's countersignature.
      contract.delegations.push Delegation.create sign claimantKeyPair,
        Message.from "utf8", toJSON delegation

      contract

  generic delegate,
    SignatureKeyPair.isType,
    SignatureKeyPair.areType,
    Contract.isType,
    isObject,
    (claimantKeyPair, revocationArray, contract, delegation) ->

      contract = delegate claimantKeyPair, contract, delegation

      unless revocationArray.length == delegation.revocations.length
        throw new Error "mismatch in number of revocation key pairs and authority definitions"

      for keyPair in revocationArray
        sign keyPair, (last contract.delegations).declaration

      contract

  delegate

export default Delegate

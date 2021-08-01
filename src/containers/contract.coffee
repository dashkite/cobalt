import { isType } from "@dashkite/joy/type"
import { isEmpty } from "@dashkite/joy/value"
import { last } from "@dashkite/joy/array"
import { fromJSON, toJSON, areType, URLTemplate } from "../utils"

assert = (predicate, message) ->
  throw new Error "verify failure: #{message}" unless predicate

compare = (signatory, key) ->
  assert signatory == key, "unsatisfied authority"

_fetch = (url) ->
  response = await fetch url,
    method: "GET"
    redirect: "follow"
    follow: 20

  if response.status == 200
    (await response.text()).trim()
  else
    throw new Error "key authority fetch failed with status #{response.status}"

# source authority is A1, destination authority is A2.
# (issuer / delegator)    (claimant, delegate)
# A2 is only for the case of authorities that use URL templates because that's a forward-referencing constraint bound and satisfied during delegation/claiming.
checkAuthority = (signatory, A1, A2) ->
  if A1.literal?
    compare signatory, A1.literal
  else if A1.url?
    compare signatory, await _fetch A1.url
  else if A1.template?
    assert A2.template?, "unsatisfied authority"

    url = URLTemplate
      .parse A1.template  # URL template
      .expand A2.template # bound parameters

    compare signatory, await _fetch url
  else
    throw new Error "malformed authority description"

Container = (library, confidential) ->
  {Grant, Delegation, Claim} = library
  {Declaration, verify, Message, hash, convert} = confidential

  class Contract

    constructor: ({@grant, @delegations, @claim}) ->
      @delegations ?= []
      @validate()

    to: (hint) ->
      contract =
        grant: @grant.to "utf8"
        delegations: (delegation.to "utf8" for delegation in @delegations)
        claim: @claim.to "utf8" if @claim?

      if hint == "utf8"
        toJSON contract
      else
        convert from: "utf8", to: hint, toJSON contract

    verify: ->
      authorityLookupPromise = @verifyAuthorities()

      @verifyEmbargo()
      @verifyExpiration()
      @verifySignatures()
      @verifyDelegationIntegrity()
      @verifyTolerance()
      parameters = @verifyTemplate()
      methods = @verifyMethods()

      await authorityLookupPromise

      {parameters, methods}

    verifyAuthorities: ->
      # Start with grant.
      assert @grant.signatories.length == (1 + @grant.revocations.length),
        "unsatisfied authority"

      await checkAuthority @grant.signatories[0], @grant.issuer

      for authority, i in @grant.revocations
        await checkAuthority @grant.signatories[i + 1], authority


      # Walk through the delegation chain.
      claimant = @grant.claimant

      for d in @delegations
        assert d.signatories.length == (1 + d.revocations.length),
          "unsatisfied authority"

        await checkAuthority d.signatories[0], claimant, d.claimant

        for authority, i in d.revocations
          await checkAuthority d.signatories[i + 1], authority

        # If delegation is valid, the delegate becomes the new claimant
        claimant = d.delegate

      # And lastly, the claim.
      assert @claim.signatories.length == 1, "unsatisfied authority"
      await checkAuthority @claim.signatories[0], claimant, @claim.claimant

    verifyEmbargo: ->
      now = new Date().toISOString()

      if (embargo = @grant.embargo)?
        assert (now > embargo), "grant is not valid until #{embargo}."

      for delegation in @delegations
        if (embargo = delegation.embargo)?
          assert (now > embargo), "delegation not valid until #{embargo}"

    verifyExpiration: ->
      now = new Date().toISOString()

      if (expires = @grant.expires)?
        assert (now < expires), "grant expired at #{expires}"

      for delegation in @delegations
        if (expires = delegation.expires)?
          assert (now < expires), "delegation expired at #{expires}"

    verifySignatures: ->
      assert @grant?.verify(), "invalid grant signature"
      assert @claim?.verify(), "invalid claim signature"

      # Does not validate delegation chain, only individual self-consistency.
      for delegation in @delegations
        assert delegation.verify(), "invalid delegation signature"

    verifyDelegationIntegrity: ->
      reference = {@grant, delegations: []}

      for delegation in @delegations
        if delegation.integrity == Delegation.integrityHash reference
          reference.delegations.push delegation
        else
          throw new Error "invalid delegation chain integrity"

    verifyTolerance: ->
      {tolerance} = @grant
      timestamp = new Date @claim.timestamp
      now = new Date()
      low = new Date()
      high = new Date()

      if (seconds = tolerance.seconds)?
        low.setSeconds now.getSeconds() - seconds
        high.setSeconds now.getSeconds() + seconds
      else if (minutes = tolerance.minutes)?
        low.setMinutes now.getMinutes() - minutes
        high.setMinutes now.getMinutes() + minutes
      else
        throw new Error "undefined grant tolerance"

      assert (low < timestamp < high), "The claim is expired."

    # URL template parameters in a claim may be specified directly in a claim or indirectly by being bound in a delegation. This validates the possible parameter binding delegation and returns the ultimate URL template parameters.
    verifyTemplate: ->
      parameters = {}
      for delegation in @delegations
        if delegation.template?
          if isEmpty parameters
            parameters = delegation.template
          else
            throw new Error "Invalid delegation. May not bind URL template in multiple delegations."

      if @claim.template?
        if isEmpty parameters
          parameters = @claim.template
        else
          throw new Error "Invalid claim. May not re-bind URL template when bound by a delegation."

      parameters

    # Allowed HTTP methods are specified in the grant and possibly narrowed in  delegation. This returns the array of ultimately allowed methods
    verifyMethods: ->
      methods = @grant.methods

      for delegation in @delegations
        _methods = []

        for method in delegation.methods
          if method in methods
            _methods.push method
          else
            throw new Error "Invalid delegation. Method is beyond scope."

        methods = _methods

      methods

    validate: ->
      unless Grant.isType @grant
        throw new Error "Invalid contract: grant failed validation."

      unless Delegation.areType @delegations
        throw new Error "Invalid contract: delegation(s) failed validation."

      if @claim? && !Claim.isType @claim
        throw new Error "Invalid contract: claim failed validation."

    @create: (value) -> new Contract value

    @from: (hint, value) ->
      new Contract do ->
        {grant, delegations, claim} = do ->
          if hint == "utf8"
            fromJSON value
          else
            fromJSON convert from: hint, to: "utf8", value

        grant: Grant.from "utf8", grant
        delegations: do ->
          for delegation in delegations
            Delegation.from "utf8", delegation
        claim: Claim.from "utf8", claim if claim?

    @isType: isType @
    @areType: areType @

export default Container

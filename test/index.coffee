import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import { sleep } from "@dashkite/joy"
import fetch from "node-fetch"
import { start, stop } from "./authority-server"

global.fetch = fetch

import Tests from "./tests"

do ->

  start()

  await print await test "Panda Capability", [
    test "Authorities", [
      test
        description: "Literal Key"
        wait: false,
        Tests.Authorities.literal

      test
        description: "URL Web Signature"
        wait: false,
        Tests.Authorities.url

      test
        description: "URL-Template Web Signature"
        wait: false,
        Tests.Authorities.template
    ]

    test "Delegation", [
      test
        description: "Full"
        wait: false,
        Tests.Delegation.full

      test
        description: "Narrowed"
        wait: false,
        Tests.Delegation.narrowed

      test
        description: "N Delegations"
        wait: false,
        Tests.Delegation.N
    ]

    test "Revocation Constraint", [
      test
        description: "Grant"
        wait: false,
        Tests.Revocation.grant

      test
        description: "Delegation"
        wait: false,
        Tests.Revocation.delegation

      test
        description: "Claimant"
        wait: false,
        Tests.Revocation.claimant
    ]

    test "Attacks", [
      test
        description: "Forgery"
        wait: false,
        Tests.Attacks.forgery

      test
        description: "Escalation"
        wait: false,
        Tests.Attacks.escalation

      test
        description: "Replay"
        wait: false,
        Tests.Attacks.replay

      test
        description: "Embargo Running"
        wait: false,
        Tests.Attacks.embargo
    ]

    test "Memoization", [
      test
        description: "Literal"
        wait: false,
        Tests.Memoization.literal
    ]

  ]

  await stop()

  process.exit if success then 0 else 1

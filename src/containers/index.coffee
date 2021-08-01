import { assign as include } from "@dashkite/joy/object"
import Claim from "./claim"
import Contract from "./contract"
import Delegation from "./delegation"
import Directory from "./directory"
import Grant from "./grant"
import Memo from "./memo"

containers = (library, confidential) ->
  include library, Grant: Grant library, confidential
  include library, Delegation: Delegation library, confidential
  include library, Claim: Claim library, confidential
  include library, Memo: Memo library, confidential
  include library, Contract: Contract library, confidential
  include library, Directory: Directory library, confidential

export default containers

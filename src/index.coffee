import Containers from "./containers"
import Functions from "./functions"

Capability = (confidential, ajv, schema) ->
  library = {ajv, schema}
  Containers library, confidential
  Functions library, confidential

export default Capability
export {schema} from "./schema"

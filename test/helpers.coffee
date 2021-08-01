import { resolve } from "path"
import { exists, mkdirp, rm, write } from "panda-quill"

root = resolve "test", "authority-fixture", "revocation"

helpers = (confidential) ->
  {SignatureKeyPair} = confidential

  addRevocationKey = (key) ->
    keyPair = await SignatureKeyPair.create()
    key = keyPair.publicKey.to "base64"
    name = keyPair.publicKey.to "safe-base64"

    await mkdirp 0o777, root

    await write (resolve root, name), key
    keyPair

  removeRevocationKey = (name) ->
    await rm resolve root, name

  {addRevocationKey, removeRevocationKey}

export default helpers

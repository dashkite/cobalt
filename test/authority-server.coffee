import { resolve } from "path"
import http from "http"
import express from "express"
import { exists, read } from "panda-quill"

server = undefined

start = ->

  app = express()
  port = 8000

  # Create server that pulls from the local key registry.
  # TODO: P9K's preset compiles the tests in build, but the fixture keys are still
  # in test uncompiled. Either format the registry as coffeescript, or change how
  # the preset is being used.
  root = resolve "test", "authority-fixture"

  app.use express.static root

  app.get "/revocation/:key", (req, res) ->
    path = resolve root, "revocation", req.params.key

    if await exists path
      res.status(200).send await read path
    else
      res.status(404).send "Not Found"

  server = app.listen port

  console.log "now running server on port #{port}"

stop = ->
  server.close()

export {start, stop}

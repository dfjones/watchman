#!/usr/bin/env coffee

cli = require 'cli'
fs = require 'fs'
path = require 'path'
winston = require 'winston'
exec = require 'child_process'
exec = exec.exec

cli.setUsage('watchman [options] target action')

cli.parse({
  "ignore-hidden": ['i', "Do not watch hidden files"],
  "rate": ['r', "Rate limit actions [like Ns, Nm, Nh, N is int]", "string", null],
  "queue": ['q', "Action queue size", "number", 1]
})

cli.main (args, options) ->
  if args.length < 2
    console.log "Please specify a target and action"
    return

  rateMap = {
    s: 1000
    m: 1000*60
    h: 1000*60*60
  }

  target = args[0]
  action = args[1]

  watched = {}

  useQueue = false
  actionQueue = []

  queueAction = ->
    if actionQueue.length < options["queue"]
      actionQueue.push(action)

  execFromQueue = ->
    for a in actionQueue
      execAction(a)
    actionQueue = []

  execAction = (toExec) ->
    toExec ?= action
    winston.info("Running action...")
    exec toExec, (error, stdout, stderr) ->
      winston.info("stderr: " + stderr)
      winston.info("stdout: " + stdout)

  watcher = (file) ->
    return if file of watched
    watched[file] = true
    winston.info("watching: #{file}")
    fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
      return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
      winston.info("File changed: " + file)
      if useQueue
        queueAction()
      else
        execAction()

  directoryWatcher = (dir) ->
    return if dir of watched
    watched[dir] = true
    winston.info("watching directory: #{dir}")
    fs.watchFile dir, {persistent: true, interval: 500}, (curr, prev) ->
      find_files(dir)

  testHidden = (file) -> options["ignore-hidden"] and file[0] is '.'

  if options["rate"]?
    useQueue = true
    rate = options["rate"]
    try
      rate = parseInt(rate[...-1]) * rateMap[rate[-1..]]
    catch error
      console.log("Error parsing rate. Rates must be expressed as Ns, Nm, Nh where N is an integer and s, m, h stand for seconds, mintues, hours respectively")
      return
    setInterval(execFromQueue, rate)

  find_files = (target) ->
    path.exists target, (exists) ->
      throw new "Target file not found: #{target}" if not exists
      fs.stat target, (err, stats) ->
        if stats.isDirectory()
          directoryWatcher(target)
          fs.readdir target, (err, files) ->
            find_files(target + "/" + file) for file in files when not testHidden(file)
        else
          watcher(target) if not testHidden(target)

  find_files(target)

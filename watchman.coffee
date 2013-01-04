#!/usr/bin/env coffee

cli = require 'cli'
eco = require 'eco'
fs = require 'fs'
path = require 'path'
exec = require 'child_process'
exec = exec.exec

cli.setUsage('watchman [options] target action')

cli.parse({
  "ignore-hidden": ['i', "Do not watch hidden files"],
  "rate": ['r', "Rate limit actions [like Ns, Nm, Nh, N is int]", "string", null],
  "queue": ['q', "Action queue size", "number", 1],
  "watch-first": ['w', "Perform the action only when there is a change. Otherwise, action is executed once immediately"]
})

getFormattedDate = () ->
  d = new Date()
  s = "#{ d.toDateString() } #{ d.toTimeString().split(" ")[0] }"

log = (s) ->
  d = getFormattedDate()
  console.log(d + " - " + s)

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

  queueAction = (action, file) ->
    if actionQueue.length < options["queue"]
      actionQueue.push([action, file])

  execFromQueue = ->
    for a in actionQueue
      execAction(a[0], a[1])
    actionQueue = []

  execAction = (toExec, file) ->
    toExec ?= action
    toExec = eco.render(toExec, {file})
    log("Running action...")
    exec toExec, (error, stdout, stderr) ->
      log("stderr: " + stderr)
      log("stdout: " + stdout)

  onFileChange = (file) ->
    log("File changed: " + file)
    if useQueue
      queueAction(action, file)
    else
      execAction(action, file)

  watcher = (file) ->
    return if file of watched
    watched[file] = true
    log("watching: #{file}")
    fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
      return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
      onFileChange(file)

  directoryWatcher = (dir) ->
    return if dir of watched
    watched[dir] = true
    log("watching directory: #{dir}")
    fs.watchFile dir, {persistent: true, interval: 500}, (curr, prev) ->
      try
        find_files(dir, true)
      catch error
        log("Error while watching dir #{dir}: #{error}")

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

  find_files = (target, quiet) ->
    fs.exists target, (exists) ->
      throw "Target file not found: #{target}" if not quiet and not exists
      fs.stat target, (err, stats) ->
        if err?
          console.log(err + " for target: " + target)
          return
        if stats? and stats.isDirectory()
          directoryWatcher(target)
          fs.readdir target, (err, files) ->
            find_files(target + "/" + file) for file in files when not testHidden(file)
        else
          watcher(target) if not testHidden(target)

  try
    find_files(target)
  catch error
    log("Error: #{error}")

  if not options["watch-first"]
    if useQueue
      queueAction()
    else
      execAction()


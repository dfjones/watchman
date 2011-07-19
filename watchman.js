(function() {
  var cli, exec, fs, getFormattedDate, log, path;
  cli = require('cli');
  fs = require('fs');
  path = require('path');
  exec = require('child_process');
  exec = exec.exec;
  cli.setUsage('watchman [options] target action');
  cli.parse({
    "ignore-hidden": ['i', "Do not watch hidden files"],
    "rate": ['r', "Rate limit actions [like Ns, Nm, Nh, N is int]", "string", null],
    "queue": ['q', "Action queue size", "number", 1]
  });
  getFormattedDate = function() {
    var d, s;
    d = new Date();
    return s = "" + (d.toDateString()) + " " + (d.toTimeString().split(" ")[0]);
  };
  log = function(s) {
    var d;
    d = getFormattedDate();
    return console.log(d + " - " + s);
  };
  cli.main(function(args, options) {
    var action, actionQueue, directoryWatcher, execAction, execFromQueue, find_files, queueAction, rate, rateMap, target, testHidden, useQueue, watched, watcher;
    if (args.length < 2) {
      console.log("Please specify a target and action");
      return;
    }
    rateMap = {
      s: 1000,
      m: 1000 * 60,
      h: 1000 * 60 * 60
    };
    target = args[0];
    action = args[1];
    watched = {};
    useQueue = false;
    actionQueue = [];
    queueAction = function() {
      if (actionQueue.length < options["queue"]) {
        return actionQueue.push(action);
      }
    };
    execFromQueue = function() {
      var a, _i, _len;
      for (_i = 0, _len = actionQueue.length; _i < _len; _i++) {
        a = actionQueue[_i];
        execAction(a);
      }
      return actionQueue = [];
    };
    execAction = function(toExec) {
            if (toExec != null) {
        toExec;
      } else {
        toExec = action;
      };
      log("Running action...");
      return exec(toExec, function(error, stdout, stderr) {
        log("stderr: " + stderr);
        return log("stdout: " + stdout);
      });
    };
    watcher = function(file) {
      if (file in watched) {
        return;
      }
      watched[file] = true;
      log("watching: " + file);
      return fs.watchFile(file, {
        persistent: true,
        interval: 500
      }, function(curr, prev) {
        if (curr.size === prev.size && curr.mtime.getTime() === prev.mtime.getTime()) {
          return;
        }
        log("File changed: " + file);
        if (useQueue) {
          return queueAction();
        } else {
          return execAction();
        }
      });
    };
    directoryWatcher = function(dir) {
      if (dir in watched) {
        return;
      }
      watched[dir] = true;
      log("watching directory: " + dir);
      return fs.watchFile(dir, {
        persistent: true,
        interval: 500
      }, function(curr, prev) {
        try {
          return find_files(dir, true);
        } catch (error) {
          return log("Error while watching dir " + dir + ": " + error);
        }
      });
    };
    testHidden = function(file) {
      return options["ignore-hidden"] && file[0] === '.';
    };
    if (options["rate"] != null) {
      useQueue = true;
      rate = options["rate"];
      try {
        rate = parseInt(rate.slice(0, -1)) * rateMap[rate.slice(-1)];
      } catch (error) {
        console.log("Error parsing rate. Rates must be expressed as Ns, Nm, Nh where N is an integer and s, m, h stand for seconds, mintues, hours respectively");
        return;
      }
      setInterval(execFromQueue, rate);
    }
    find_files = function(target, quiet) {
      return path.exists(target, function(exists) {
        if (!quiet && !exists) {
          throw "Target file not found: " + target;
        }
        return fs.stat(target, function(err, stats) {
          if (err != null) {
            console.log(err + " for target: " + target);
            return;
          }
          if ((stats != null) && stats.isDirectory()) {
            directoryWatcher(target);
            return fs.readdir(target, function(err, files) {
              var file, _i, _len, _results;
              _results = [];
              for (_i = 0, _len = files.length; _i < _len; _i++) {
                file = files[_i];
                if (!testHidden(file)) {
                  _results.push(find_files(target + "/" + file));
                }
              }
              return _results;
            });
          } else {
            if (!testHidden(target)) {
              return watcher(target);
            }
          }
        });
      });
    };
    try {
      return find_files(target);
    } catch (error) {
      return log("Error: " + error);
    }
  });
}).call(this);

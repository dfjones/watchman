Watchman
========

Simple utility that watches files/directories for changes and performs an action when they change. Inspired (and partially based on) the coffee-script compiler.

I'm sure this is reinventing 100 other, better tools.

Yes I wrote it in coffee-script and NodeJS. Does that make me hip now?

(Calm down, you don't need coffee-script to run it.)

Examples:

    ./watchman watchman "ls -lah"
    Tue Apr 12 2011 23:06:42 - watching: watchman
    Tue Apr 12 2011 23:06:51 - File changed: watchman
    Tue Apr 12 2011 23:06:51 - Running action...
    Tue Apr 12 2011 23:06:52 - stderr: 
    Tue Apr 12 2011 23:06:52 - stdout: total 80
    drwxr-xr-x  10 doug  doug   340B Apr 12 23:06 .
    drwxr-xr-x@ 26 doug  doug   884B Apr  7 22:17 ..
    -rw-r--r--   1 doug  doug    12K Apr 12 23:06 .README.swp
    drwxr-xr-x  15 doug  doug   510B Apr 12 23:06 .git
    drwxrwxr-x   5 doug  doug   170B Apr 12 23:06 .vimbackup
    -rw-r--r--   1 doug  doug    12K Apr 12 23:00 .watchman.coffee.swp
    -rw-r--r--   1 doug  doug   497B Apr 12 23:06 README
    drwxr-xr-x   7 doug  doug   238B Apr  3 13:14 test
    -rwxr-xr-x   1 doug  doug   4.1K Apr 12 23:06 watchman
    -rwxr-xr-x   1 doug  doug   2.6K Apr 12 23:00 watchman.coffee


Works with directories too!

    ./watchman test "echo 'hello world'"
    Tue Apr 12 2011 23:07:32 - watching directory: test
    Tue Apr 12 2011 23:07:32 - watching: test/file2
    Tue Apr 12 2011 23:07:32 - watching: test/bar
    Tue Apr 12 2011 23:07:32 - watching: test/file3
    Tue Apr 12 2011 23:07:32 - watching: test/foo
    Tue Apr 12 2011 23:07:39 - File changed: test/foo
    Tue Apr 12 2011 23:07:39 - Running action...
    Tue Apr 12 2011 23:07:39 - stderr: 
    Tue Apr 12 2011 23:07:39 - stdout: hello world

Not only that, but it will find new files in any watched directory!

    ./watchman test "echo 'hello world'"
    Tue Apr 12 2011 23:08:30 - watching directory: test
    Tue Apr 12 2011 23:08:30 - watching: test/bar
    Tue Apr 12 2011 23:08:30 - watching: test/file2
    Tue Apr 12 2011 23:08:30 - watching: test/file3
    Tue Apr 12 2011 23:08:30 - watching: test/foo

Later after adding the file...

    Tue Apr 12 2011 23:08:36 - watching: test/newFile


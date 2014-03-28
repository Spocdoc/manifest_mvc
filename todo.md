# optimization

 - compile all the stylus stylesheets together as a single file after doing dependency analysis and removing `@import` statements

    this is to avoid duplicate definitions across files when using `@extend`

# error avoidance

 - manifest updating should create a temp file then move, rather than directly overwriting the exiting manifest (in case the program is killed in medias)

    this is implemented but not working -- very often if there's a compilation error, the manifest is blank...


# rewriting

 - when rewriting the manifest, don't use the options that are in memory, as these may have been overridden by command-line args. instead, rewrite using the same options that were originally present in the file

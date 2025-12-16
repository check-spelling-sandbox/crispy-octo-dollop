# hocon-validator/formatter

A simple action to reformat hocon files

## inputs

Name|Default|Description
-|-|-
artifact-name | _based on GitHub workflow run_ | name for artifact containing updated files
hocon-files | | space delimited list of file names
hocon-file-list | | path to null delimited list of file names
indentation | 2 | number of spaces to use for each indent step
parallel-tasks | _automatic_ | number of files to format concurrently
suppress-summary | | skip GitHub step summary

While none of the options are individually required, at least one of `hocon-files` or `hocon-file-list` must be specified.

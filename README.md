This simple Bash function can scan through robot files and grab specific sections from it, 
in this case the function returns test-case names, test-case traces and two versions of its 
documentation, one suitable for HP ALM system.

The function calles a LOGGER, which can be as simple as this:
```shell
LOGGER(){
    local data=$1
    local _timestamp
    read _timestamp < <(date +"%d/%M/%Y %T")
    printf '%s\n' "[$\_timestamp] <${FUNCNAME[1]}()> $data" \
                   | tee -a ${path_where_script_running}/${logger_file}
}
```

# some hard-coded strings may need to be changed based on the specific robot file format

parse_robot(){
# usage: parse_robot robot_file -> testcase_names -> testcase_traces 
# -> tescase_documentations send_to_alm_documentation

    local robot_file=$1; shift
    local -n _testcase_names=$1; shift
    local -n _testcase_traces=$1; shift
    local -n _tescase_documentations=$1; shift
    local -n _send_to_alm_documentation=$1;
    local trace_data
    local doc_data
    local line_counter=1
    local total_lines
    local documentation_found=false
    local robot_file_name
    local test_name
    read total_lines < <(wc -l < $robot_file)
    read robot_file_name < <(basename $robot_file) #| sed -e 's/.robot//' -e 's/_/ /g')
    LOGGER "parsing Robot test-cases in [$robot_file_name] has started ... "
    printf "<$robot_file_name> is being parsed ... "
    # for spinner
    local i=1
    local sp="/-\|"
    echo -n ' '
    while :; do
        saved_ifs=$IFS
        IFS=
        read -r line < <(tail -n +${line_counter} $robot_file)
        IFS="$saved_ifs"
        if [[ "$line" = "*** Test Cases ***" ]]; then
            while [[ $line_counter -le $((total_lines + 5)) ]]; do
                # spin cursor
                printf "\b${sp:i++%${#sp}:1}"
                saved_ifs=$IFS
                IFS=
                read -r line < <(tail -n +${line_counter} $robot_file)
                IFS="$saved_ifs"
                # inside test case
                if [[ "$line" =~ ^[[:alpha:]] ]]; then
                    read test_name < <(echo "$line" | sed 's/ /_/g')
                    _testcase_names+=("$test_name")
                    line_counter=$(( line_counter + 1 ))
                    while [[ $line_counter -le $((total_lines + 5)) ]]; do
                        saved_ifs=$IFS
                        IFS=
                        read -r line < <(tail -n +${line_counter} $robot_file)
                        IFS="$saved_ifs"
                        # inside testcase body
                        if [[ "$line" =~ ^[[:space:]]{2,} ]] || [[ -z "$line" ]] ; then
                            if grep "TRACE" <<< $line >> /dev/null; then
                                trace_data=''
                                while :; do
                                    for (( i=0; i<${#line}; i++ )); do
                                        if [[ "${line:$i:1}" = "}" ]]; then
                                            trace_data+="${line:$i:1}"
                                            break 2
                                        else
                                            trace_data+="${line:$i:1}"
                                        fi
                                    done
                                    line_counter=$(( line_counter + 1 ))
                                    saved_ifs=$IFS
                                    IFS=
                                    read -r line < <(tail -n +${line_counter} $robot_file)
                                    IFS="$saved_ifs"
                                done
                                read trace_data < <(echo "$trace_data" \
                                                        | grep -o TRACE{.*} \
                                                        | cut -d "{" -f2 \
                                                        | cut -d "}" -f1)
                                _testcase_traces+=(["$test_name"]="${trace_data:-none}")
                            fi
                            if grep "Documentation" <<< $line >> /dev/null; then
                                documentation_found=true
                                doc_data=''
                                alm_doc_data=''
                                while :; do
                                    read -r alm_line < <(sed -e 's/\&/\&#038;/g' -e 's/</\&#060;/g' -e 's/>/\&#062;/g' <<< $line)
                                    alm_doc_data+="${alm_line}&#010;"
                                    doc_data+="$line"
                                    line_counter=$(( line_counter + 1 ))
                                    IFS=
                                    read -r line < <(tail -n +${line_counter} $robot_file)
                                    IFS="$saved_ifs"
                                    if [[ "$line" =~ ^[[:space:]]{2,}(\.).*$ ]]; then
                                        :
                                    else
                                        line_counter=$(( line_counter - 1 ))
                                        break
                                    fi
                                done
                                read doc_data < <(echo $doc_data | sed 's/ \+$//g')
                                _tescase_documentations+=(["$test_name"]="${doc_data:-none}")
                                _send_to_alm_documentation+=(["$test_name"]="${alm_doc_data:-none}")
                            fi
                        else
                            line_counter=$(( line_counter - 1 ))
                            break
                        fi
                        line_counter=$(( line_counter + 1 ))
                    done
                    if [[ $documentation_found = false ]]; then
                        _tescase_documentations+=(["$test_name"]="No documentations")
                        _send_to_alm_documentation+=(["$test_name"]="No documentations")
                    else
                    documentation_found=false
                    fi
                elif [[ "$line" = "*** Keywords ***" ]]; then
                    break
                else
                    # what else?
                    :
                fi
                line_counter=$(( line_counter + 1 ))
            done
        break
        fi
        line_counter=$(( line_counter + 1 ))
    done
    echo
}

#!/bin/bash
export BASHDBG_PROMPT_COLOR=$'\x1b\x5b32m'
export BASHDBG_COLOR_END=$'\x1b\x5b0m'
export BASHDBG_BP=""


bashdbg_print_excerpt() {
	awk -v l=${2} -v c=5 \
		'BEGIN{i=length(l+c)+2}NR>=l-c&&NR<=l+c{printf "%s%"i"s %s\n",NR==l?"->":"  ",NR,$0}' \
		"${1}" | pygmentize -l bash
}


bashdbg_page_file() {
	local file=${1}
	local lnum=${2}

	awk -v lnum="${lnum}" -v len="$(wc -l < "${file}")" \
		'BEGIN{i=length(len)+2}{printf "%s%"i"s %s\n",NR==lnum?"->":"  ",NR,$0}' \
		"${file}" | pygmentize -l bash | less +"${lnum}" -rFX
}


handle_debug() {
	local lnum=${1}
	local file=${2}

	bashdbg_prompt=${BASHDBG_PROMPT_COLOR}"(dbg) > "${BASHDBG_COLOR_END}
	while true ; do
		echo "$PS4 $(sed "$lnum!d" "$file")"
		read -ep "${bashdbg_prompt}" command_line
		# command_line=$(rlwrap -H "$hist" bash -c "read -p '$bashdbg_prompt' REPLY && echo $REPLY")
		echo $command_line
		if [ -z "${command_line}" ] ; then
			command_line="${bashdbg_prev_command_line}"
		fi
		bashdbg_prev_command_line="${command_line}"
		case "${command_line}" in
			"n")
				return 0
				;;
			"ll")
				bashdbg_page_file "${file}" "${lnum}"
				;;
			"l")
				bashdbg_print_excerpt "${file}" "${lnum}"
				;;
			"skip")
				return 2
				;;
			"q")
				echo "Stop debugging session and terminate program ..."
				exit 127
				;;
			"b")
				;;
			"")
				;;
			*)
				eval "${command_line}"
				;;
		esac
	done
}


export -f bashdbg_print_excerpt
export -f bashdbg_page_file
export -f handle_debug


hist=~/.bashdb_history
shopt -s extdebug
trap 'handle_debug "${LINENO}" "${BASH_SOURCE}"' DEBUG

. "$1"

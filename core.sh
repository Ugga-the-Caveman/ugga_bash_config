# UGGA-BASH-CONFIGURATION CORE FILE
# UBC_CORE_VERSION="2026-07-01"

echo "core.sh loaded"

UBC_GLOBAL_DIR="/usr/lib/ugga_bash_config"
UBC_USER_DIR="$HOME/.ubc"


# ---------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------
# Path-Dateien enthalten Verzeichnisse, die der $PATH-Variable
# hinzugefügt werden.
#
# Jede Zeile enthält genau ein Verzeichnis.
#
# Syntax:
#   /scripts      → fügt nur dieses Verzeichnis hinzu
#   /scripts/     → ebenfalls nur dieses Verzeichnis
#                   (ein abschließender Slash wird entfernt)
#   /scripts/*    → fügt dieses Verzeichnis und alle Unterverzeichnisse
#                   rekursiv hinzu
#
# Es gibt eine globale Path-Datei sowie eine benutzerspezifische
# Path-Datei. Beide sind optional.
#
# Verarbeitungsreihenfolge:
#   1. Von der Distribution gesetzte Pfade (z. B. in /etc/profile, bashrc)
#   2. Benutzer-Path-Datei
#   3. Globale Path-Datei
#
# Einträge werden an das Ende von $PATH angehängt.
# Doppelte Einträge werden vermieden.
#
# Nicht existierende Verzeichnisse werden nicht hinzugefügt.
# Relative Pfade sind nicht erlaubt.
#
# In den Path-Dateien können Variablen wie $HOME oder $USER
# verwendet werden.
#
# Leerzeilen und Kommentarzeilen (# ...) werden ignoriert.


ubc_add_path() {
    local line="$1"
    local cleared_line recursive=false dir

    # Kommentar entfernen
    cleared_line="${line%%#*}"

    # Whitespace trimmen
    cleared_line="${cleared_line#"${cleared_line%%[![:space:]]*}"}"
    cleared_line="${cleared_line%"${cleared_line##*[![:space:]]}"}"

    [[ -z "$cleared_line" ]] && return

    # Rekursiv?
    if [[ "$cleared_line" == *\* ]]; then
        cleared_line="${cleared_line%?}"
        recursive=true
    fi

    # Variablen expandieren
    cleared_line=$(printf '%s' "$cleared_line" | envsubst)

    # Nur absolute Pfade erlaubt
    [[ "$cleared_line" != /* ]] && return

    cleared_line="${cleared_line%%/}"


    [[ ! -d "$cleared_line" ]] && return


    add_dir() {
        case ":$PATH:" in
            *:"$dir":*) ;;   # schon drin → nix tun
            *) PATH="${PATH:+$PATH:}$dir" ;;
        esac
#         echo "[debug] $dir"
    }

    if $recursive; then
        while IFS= read -r dir; do
            add_dir "$dir"
        done < <(find "$cleared_line" -type d)
    else
        add_dir "$cleared_line"
    fi
}


ubc_read_path_file() {
    local path_file="$1"

    if [[ ! -r "$path_file" ]]; then
        return
    fi

    while IFS= read -r line; do
        ubc_add_path "$line"
    done < "$path_file"
}

ubc_read_path_file "$UBC_USER_DIR/path"
ubc_read_path_file "$UBC_GLOBAL_DIR/path"

unset -f ubc_read_path_file

# ---------------------------------------------------------------------
# Skip non-interactive shells
# ---------------------------------------------------------------------
[[ $- != *i* ]] && return 0

#optionaler schutz, das es nicht kracht wenn das file direkt in bash ausgeführt wird anstatt gesourced zu werden.
#[[ $- != *i* ]] && { return 0 2>/dev/null || exit 0; }



# ---------------------------------------------------------------------
# prompt hooks
# ---------------------------------------------------------------------

declare -ag UBC_PREEXEC_HOOKS=()
declare -ag UBC_PROMPT_HOOKS=()


ubc_add_hook() {
    local hook_type="$1"
    local func="$2"
    local -n hook_array

    [[ -n "$func" ]] || return 1
    [[ "$func" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    declare -F "$func" >/dev/null || {
        echo "ubc_add_hook: function '$func' not found" >&2
        return 1
    }

    case "$hook_type" in
        preexec) hook_array=UBC_PREEXEC_HOOKS ;;
        prompt)  hook_array=UBC_PROMPT_HOOKS ;;
        *)
            echo "ubc_add_hook: unknown hook '$hook_type'" >&2
            return 1
            ;;
    esac

    local f
    for f in "${hook_array[@]}"; do
        [[ "$f" == "$func" ]] && return 0
    done

    hook_array+=("$func")
}


add_to_preexec() {
    ubc_add_hook preexec "$1"
}


add_to_prompt_command() {
    ubc_add_hook prompt "$1"
}


ubc_run_preexec_hooks() {
    local func

    for func in "${UBC_PREEXEC_HOOKS[@]}"; do
        "$func"
    done
}


ubc_run_prompt_hooks() {
    local func

    for func in "${UBC_PROMPT_HOOKS[@]}"; do
        "$func"
    done
}


PS0='${ ubc_run_preexec_hooks; }'
PROMPT_COMMAND=ubc_run_prompt_hooks


# ---------------------------------------------------------------------
# custom modules
# ---------------------------------------------------------------------

ubc_load_custom_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || return

    local f
    for f in "$dir"/*.sh; do
        [[ -f "$f" ]] || continue
        # shellcheck source=/dev/null
        . "$f"
    done
}

ubc_load_custom_dir "$UBC_GLOBAL_DIR/custom.d"
ubc_load_custom_dir "$UBC_USER_DIR/custom.d"

unset -f ubc_load_custom_dir

# ---------------------------------------------------------------------
# prompt
# ---------------------------------------------------------------------
# if user has a prompt file, use that.
# else use the global prompt file.
# if both are not available, use a simple fallback prompt,

prompt_file=""

if [[ -f "$UBC_USER_DIR/prompt.sh" ]]; then
    prompt_file="$UBC_USER_DIR/prompt.sh"
elif [[ -f "$UBC_GLOBAL_DIR/prompt.sh" ]]; then
    prompt_file="$UBC_GLOBAL_DIR/prompt.sh"
fi

if [[ -n "$prompt_file" ]]; then
    # shellcheck source=/dev/null
    . "$prompt_file"
else
    PS1='\u@\h:\w\$ '
fi

echo "core.sh end"

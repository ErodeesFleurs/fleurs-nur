#!@bash@
set -euo pipefail
export PATH="@runtimePath@${PATH:+:$PATH}"

binary="@game@/libexec/${0##*/}"
[[ ${0##*/} != openstarbound ]] || binary="@game@/libexec/starbound"
for arg in "$@"; do
  case "$arg" in
    --) break ;;
    -bootconfig) exec "$binary" "$@" ;;
  esac
done

# Defaults are JSON data, never sourced shell code. NUL separators preserve
# colons, quotes, whitespace and newlines inside individual directory names.
mapfile -d '' -t defaults < <(jq -j '
  [.starboundAssetsPath // "", .storageDir // "", .logDir // "",
   .modDir // "", .extraAssetDirs[]] | .[] | ., "\u0000"
' '@defaults@')
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_dir="${OPENSTARBOUND_RUNTIME_DIR:-$data_home/OpenStarbound}"

# Expand only documented leading home/data prefixes. No eval, command
# substitution or general environment interpolation of configuration strings.
expand_path() {
  case "$1" in
    '$HOME') REPLY="$HOME" ;;
    '$HOME/'*) REPLY="$HOME/${1#\$HOME/}" ;;
    '${HOME}') REPLY="$HOME" ;;
    '${HOME}/'*) REPLY="$HOME/${1#\$\{HOME\}/}" ;;
    '~/'*) REPLY="$HOME/${1#\~/}" ;;
    '$XDG_DATA_HOME') REPLY="$data_home" ;;
    '$XDG_DATA_HOME/'*) REPLY="$data_home/${1#\$XDG_DATA_HOME/}" ;;
    '${XDG_DATA_HOME}') REPLY="$data_home" ;;
    '${XDG_DATA_HOME}/'*) REPLY="$data_home/${1#\$\{XDG_DATA_HOME\}/}" ;;
    *) REPLY="$1" ;;
  esac
  [[ "$REPLY" == /* ]] || REPLY="$PWD/$REPLY"
}
expand_path "${OPENSTARBOUND_ASSETS:-${defaults[0]:-$HOME/.local/share/Steam/steamapps/common/Starbound/assets}}"
assets="$REPLY"
expand_path "${OPENSTARBOUND_STORAGE:-${defaults[1]:-$runtime_dir/storage}}"
storage="$REPLY"
expand_path "${OPENSTARBOUND_LOGS:-${defaults[2]:-$runtime_dir/logs}}"
logs="$REPLY"
expand_path "${OPENSTARBOUND_MODS:-${defaults[3]:-$runtime_dir/mods}}"
mods="$REPLY"
asset_dirs=("$assets" '@game@/share/openstarbound/assets')
for dir in "${defaults[@]:4}"; do
  expand_path "$dir"
  asset_dirs+=("$REPLY")
done
asset_dirs+=("$mods")

print_config() {
  jq -n --arg storage "$storage" --arg logs "$logs" --args '
    {assetDirectories: $ARGS.positional, storageDirectory: $storage, logDirectory: $logs}
  ' -- "${asset_dirs[@]}"
}
for arg in "$@"; do
  if [[ "$arg" == --print-bootconfig ]]; then
    print_config
    exit 0
  fi
  [[ "$arg" != -- ]] || break
done

mkdir -p -- "$storage" "$logs" "$mods"
# Each invocation owns a private random directory. No predictable shared file
# or symlink target; keep the config alive until the engine has exited.
temp_root="${TMPDIR:-/tmp}"
[[ "$temp_root" == /* ]] || temp_root="$PWD/$temp_root"
config_dir=$(mktemp -d "$temp_root/openstarbound.XXXXXXXXXX")
trap 'rm -rf -- "$config_dir"' EXIT
print_config > "$config_dir/sbinit.config"

forward_signal() {
  local signal="$1" status="$2"
  trap - "$signal"
  kill -s "$signal" "$child" 2>/dev/null || :
  wait "$child" 2>/dev/null || :
  exit "$status"
}
# Bash ignores INT/QUIT in asynchronous children; reset them before exec so
# forwarded Ctrl-C reaches the engine rather than leaving the supervisor stuck.
env --default-signal=INT,QUIT "$binary" -bootconfig "$config_dir/sbinit.config" "$@" <&0 &
child=$!
trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
status=0
wait "$child" || status=$?
exit "$status"

#!/bin/sh
# Registers (or removes) the F5 BIG-IP device-cert-connector MACHINE plugin
# on this VSatellite: patches the local container registry mirror so this
# VSat can pull the plugin's public ghcr.io image, then registers the plugin
# against the caller's Venafi tenant.
#
# Usage:
#   curl -fsSL <url>/activate-f5-connector.sh | sh -                # activate (default)
#   curl -fsSL <url>/activate-f5-connector.sh | sh -s -- --remove   # remove the plugin
#   curl -fsSL <url>/activate-f5-connector.sh | sh -s -- --help     # show this help
#
# After activation succeeds, add the actual F5 device as a Machine via the
# normal Venafi Control Plane UI (Machines -> Add Machine -> "F5 BIG-IP LTM
# Device Certificate") -- that part is standard product usage, not scripted
# here. --remove only deregisters the plugin itself; it does not touch any
# Machines already created from it or revert the registry mirror patch.

set -eu

SCRIPT_VERSION="2026-07-18.7-manifest-deploy"
PLUGIN_NAME="F5 BIG-IP LTM Device Certificate"
PLUGIN_IMAGE="ghcr.io/tall27/f5-device-cert-connector@sha256:5d0040bf49c482337600728466abc629d90ba25349cc9176da97235a8df24071"
REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"
TTY=/dev/tty

MANIFEST_URL_PLACEHOLDER="ewogICJuYW1lIjogIkY1IEJJRy1JUCBMVE0gRGV2aWNlIENlcnRpZmljYXRlIiwKICAiZGVzY3JpcHRpb24iOiAiRGlzY292ZXJzIGFuZCBwcm92aXNpb25zIHRoZSBGNSBCSUctSVAgbWFuYWdlbWVudCBHVUkgKGh0dHBkKSBUTFMgY2VydGlmaWNhdGUuIFNlcGFyYXRlIGZyb20gdGhlIGdlbmVyYWwgRjUgQklHLUlQIExUTSBjb25uZWN0b3IsIHdoaWNoIG1hbmFnZXMgdmlydHVhbC1zZXJ2ZXIgU1NMIHByb2ZpbGVzLiIsCiAgIndvcmtUeXBlcyI6IFsKICAgICJQUk9WSVNJT05JTkciLAogICAgIkRJU0NPVkVSWSIKICBdLAogICJwbHVnaW5UeXBlIjogIk1BQ0hJTkUiLAogICJkb21haW5TY2hlbWEiOiB7CiAgICAiYmluZGluZyI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgInRhcmdldCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAiZGVmYXVsdCI6ICJtYW5hZ2VtZW50LWludGVyZmFjZSIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJ0YXJnZXQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIsCiAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImJpbmRpbmcubGFiZWwiCiAgICB9LAogICAgImNvbm5lY3Rpb24iOiB7CiAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICJob3N0bmFtZU9yQWRkcmVzcyI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJhZGRyZXNzLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAwCiAgICAgICAgfSwKICAgICAgICAicG9ydCI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJwb3J0LmRlc2NyaXB0aW9uIiwKICAgICAgICAgICJtYXhpbXVtIjogNjU1MzUsCiAgICAgICAgICAibWluaW11bSI6IDEsCiAgICAgICAgICAidHlwZSI6ICJpbnRlZ2VyIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBvcnQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDEKICAgICAgICB9LAogICAgICAgICJ1c2VybmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1lbmNyeXB0ZWQiOiB0cnVlLAogICAgICAgICAgIngtbGFiZWxMb2NhbGl6YXRpb25LZXkiOiAidXNlcm5hbWUubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDIKICAgICAgICB9LAogICAgICAgICJwYXNzd29yZCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1jb250cm9sT3B0aW9ucyI6IHsKICAgICAgICAgICAgInBhc3N3b3JkIjogdHJ1ZSwKICAgICAgICAgICAgInNob3dQYXNzd29yZExhYmVsIjogInBhc3N3b3JkLnNob3dQYXNzd29yZCIsCiAgICAgICAgICAgICJoaWRlUGFzc3dvcmRMYWJlbCI6ICJwYXNzd29yZC5oaWRlUGFzc3dvcmQiCiAgICAgICAgICB9LAogICAgICAgICAgIngtZW5jcnlwdGVkIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBhc3N3b3JkLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAzCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImhvc3RuYW1lT3JBZGRyZXNzIiwKICAgICAgICAidXNlcm5hbWUiLAogICAgICAgICJwYXNzd29yZCIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJrZXlzdG9yZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJjZXJ0aWZpY2F0ZU5hbWUuZGVzY3JpcHRpb24iLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNlcnRpZmljYXRlTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMCwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9LAogICAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciLAogICAgICAgICAgIngtaGlkZGVuIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNoYWluTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMSwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJyZXF1aXJlZCI6IFsKICAgICAgICAiY2VydGlmaWNhdGVOYW1lIgogICAgICBdLAogICAgICAidHlwZSI6ICJvYmplY3QiLAogICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJrZXlzdG9yZS5sYWJlbCIsCiAgICAgICJ4LXByaW1hcnlLZXkiOiBbCiAgICAgICAgIiMvY2VydGlmaWNhdGVOYW1lIgogICAgICBdCiAgICB9LAogICAgImNlcnRpZmljYXRlQnVuZGxlIjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiY2VydGlmaWNhdGUiOiB7CiAgICAgICAgICAiY29udGVudEVuY29kaW5nIjogImJhc2U2NCIsCiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAiY2VydGlmaWNhdGVDaGFpbiI6IHsKICAgICAgICAgICJjb250ZW50RW5jb2RpbmciOiAiYmFzZTY0IiwKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9LAogICAgICAgICJwcml2YXRlS2V5IjogewogICAgICAgICAgImNvbnRlbnRFbmNvZGluZyI6ICJiYXNlNjQiLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWVuY3J5cHRlZC1iYXNlNjQiOiB0cnVlCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImNlcnRpZmljYXRlIiwKICAgICAgICAicHJpdmF0ZUtleSIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJtZXRhZGF0YSI6IHsKICAgICAgInR5cGUiOiAib2JqZWN0IiwKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9CiAgICAgIH0KICAgIH0sCiAgICAiZGlzY292ZXJ5IjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiZXhjbHVkZUV4cGlyZWRDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgICAidHlwZSI6ICJib29sZWFuIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImRpc2NvdmVyeS5leHBpcmVkQ2VydGlmaWNhdGVzTGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5Q29udHJvbCI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgIm1heFJlc3VsdHMiOiB7CiAgICAgICAgICAidHlwZSI6ICJpbnQiCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgIm1heFJlc3VsdHMiCiAgICAgIF0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5UGFnZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImRpc2NvdmVyeVR5cGUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAicGFnaW5hdG9yIjogewogICAgICAgICAgInR5cGUiOiAic3RyaW5nIgogICAgICAgIH0KICAgICAgfSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfQogIH0sCiAgImxvY2FsaXphdGlvblJlc291cmNlcyI6IHsKICAgICJlbiI6IHsKICAgICAgImFkZHJlc3MiOiB7CiAgICAgICAgImxhYmVsIjogIkY1IEJJRy1JUCBBZGRyZXNzL0hvc3RuYW1lIgogICAgICB9LAogICAgICAicG9ydCI6IHsKICAgICAgICAiZGVzY3JpcHRpb24iOiAiTm8gdmFsdWUgaXMgaW50ZXJwcmV0ZWQgYXMgNDQzIiwKICAgICAgICAibGFiZWwiOiAiUG9ydCIKICAgICAgfSwKICAgICAgInVzZXJuYW1lIjogewogICAgICAgICJsYWJlbCI6ICJVc2VybmFtZSIKICAgICAgfSwKICAgICAgInBhc3N3b3JkIjogewogICAgICAgICJsYWJlbCI6ICJQYXNzd29yZCIsCiAgICAgICAgInNob3dQYXNzd29yZCI6ICJTaG93IFBhc3N3b3JkIiwKICAgICAgICAiaGlkZVBhc3N3b3JkIjogIkhpZGUgUGFzc3dvcmQiCiAgICAgIH0sCiAgICAgICJrZXlzdG9yZSI6IHsKICAgICAgICAibGFiZWwiOiAiRGV2aWNlIENlcnRpZmljYXRlIEluZm9ybWF0aW9uIgogICAgICB9LAogICAgICAiY2VydGlmaWNhdGVOYW1lIjogewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJIb3cgdGhlIGNlcnRpZmljYXRlIHNob3VsZCBhcHBlYXIgb24gdGhlIEY1IEJJRy1JUCIsCiAgICAgICAgImxhYmVsIjogIkNlcnRpZmljYXRlIE5hbWUiCiAgICAgIH0sCiAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgImxhYmVsIjogIkNoYWluIEJ1bmRsZSBOYW1lIgogICAgICB9LAogICAgICAiYmluZGluZyI6IHsKICAgICAgICAibGFiZWwiOiAiTWFuYWdlbWVudCBJbnRlcmZhY2UiCiAgICAgIH0sCiAgICAgICJ0YXJnZXQiOiB7CiAgICAgICAgImxhYmVsIjogIlRhcmdldCIsCiAgICAgICAgImRlc2NyaXB0aW9uIjogIlRoZXJlIGlzIG9ubHkgb25lIHRhcmdldDogdGhlIEY1IG1hbmFnZW1lbnQgR1VJLiBObyBzZWxlY3Rpb24gbmVlZGVkLiIKICAgICAgfSwKICAgICAgImRpc2NvdmVyeSI6IHsKICAgICAgICAiZXhwaXJlZENlcnRpZmljYXRlc0xhYmVsIjogIkV4Y2x1ZGUgZXhwaXJlZCBjZXJ0aWZpY2F0ZXMiCiAgICAgIH0KICAgIH0KICB9LAogICJob29rcyI6IHsKICAgICJtYXBwaW5nIjogewogICAgICAiY29uZmlndXJlSW5zdGFsbGF0aW9uRW5kcG9pbnQiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2NvbmZpZ3VyZWluc3RhbGxhdGlvbmVuZHBvaW50IiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZGlzY292ZXJDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2Rpc2NvdmVyY2VydGlmaWNhdGVzIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZ2V0VGFyZ2V0Q29uZmlndXJhdGlvbiI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvZ2V0dGFyZ2V0Y29uZmlndXJhdGlvbiIsCiAgICAgICAgInJlcXVlc3QiOiBudWxsLAogICAgICAgICJyZXNwb25zZSI6IG51bGwKICAgICAgfSwKICAgICAgImluc3RhbGxDZXJ0aWZpY2F0ZUJ1bmRsZSI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvaW5zdGFsbGNlcnRpZmljYXRlYnVuZGxlIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAidGVzdENvbm5lY3Rpb24iOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL3Rlc3Rjb25uZWN0aW9uIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9CiAgICB9LAogICAgInJlcXVlc3RDb252ZXJ0ZXJzIjogWwogICAgICAiYXJndW1lbnRzLWRlY3J5cHRlciIKICAgIF0KICB9Cn0K"

print_help() {
    cat <<HELP
Usage: activate-f5-connector.sh [--remove|--help]

  (no argument)   Register the F5 BIG-IP device-cert-connector MACHINE
                  plugin on this VSatellite's Venafi tenant. Patches this
                  VSat's registry mirror to allow pulling the plugin's
                  public ghcr.io image, then registers/updates the plugin.

  --remove, -r    Remove the "$PLUGIN_NAME" plugin registration from the
                  tenant. Prompts for confirmation before deleting. Does not
                  delete any Machines already created from this plugin, and
                  does not revert the registry mirror patch.

  --help, -h      Show this help and exit.

When piped through curl, pass flags after "sh -s --", e.g.:
  curl -fsSL <url>/activate-f5-connector.sh | sh -s -- --remove
HELP
}

printf '(activate-f5-connector.sh %s)\n' "$SCRIPT_VERSION" >&2

ACTION="activate"
case "${1:-}" in
    "") ;;
    --help|-h) print_help; exit 0 ;;
    --remove|-r) ACTION="remove" ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; print_help >&2; exit 1 ;;
esac

log() {
    printf '==> %s\n' "$1"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

# Run a command quietly; only show its output if it fails.
run_quiet() {
    _reason="$1"
    shift
    log "$_reason"
    _out="$(mktemp)"
    if ! "$@" >"$_out" 2>&1; then
        printf 'ERROR: command failed: %s\n' "$*" >&2
        cat "$_out" >&2
        rm -f "$_out"
        exit 1
    fi
    rm -f "$_out"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

# --- Preflight -----------------------------------------------------------

[ -r "$TTY" ] || fail "no controlling terminal (/dev/tty) -- run this interactively, not from a non-interactive job"

require_cmd curl
require_cmd sed
require_cmd base64
require_cmd mktemp
require_cmd diff

# VSatellite appliances are typically operated as root directly (no separate
# sudo user exists); a regular Linux box might have you sudo in instead.
# Only require/use sudo when not already root.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    require_cmd sudo
    SUDO="sudo"
fi

if command -v jq >/dev/null 2>&1; then
    HAVE_JQ=1
else
    HAVE_JQ=0
    if [ "$ACTION" = "remove" ]; then
        fail "jq is required for --remove (safe plugin lookup/deletion needs reliable JSON parsing) -- install jq and re-run"
    fi
    log "jq not found -- will not be able to detect an already-registered plugin, every run will attempt to create a new one instead of updating"
fi

# Keep the API key out of `ps` output (curl -H puts headers in argv) and off
# the terminal echo: read with echo disabled, pass it to curl via a
# owner-only-readable config file instead of a -H argument.
CURL_CFG="$(mktemp)"
chmod 600 "$CURL_CFG"
trap 'rm -f "$CURL_CFG"' EXIT

printf 'Venafi tenant API key: '
stty -echo 2>/dev/null || true
read -r API_KEY < "$TTY"
stty echo 2>/dev/null || true
printf '\n'
[ -n "$API_KEY" ] || fail "no API key entered"
printf 'header = "tppl-api-key: %s"\n' "$API_KEY" > "$CURL_CFG"

API_BASE=""
for base in https://api.venafi.cloud https://api.eu.venafi.cloud https://api.au.venafi.cloud https://api.uk.venafi.cloud https://api.ca.venafi.cloud; do
    if curl -fsS -K "$CURL_CFG" "$base/v1/environments" >/dev/null 2>&1; then
        API_BASE="$base"
        break
    fi
done
[ -n "$API_BASE" ] || fail "could not reach Venafi TLS Protect Cloud with that API key in any region"

api_get() {
    curl -fsS -K "$CURL_CFG" "$API_BASE/$1"
}

api_post() {
    curl -fsS -K "$CURL_CFG" -H "Content-Type: application/json" -X POST -d "$2" "$API_BASE/$1"
}

api_patch() {
    curl -fsS -K "$CURL_CFG" -H "Content-Type: application/json" -X PATCH -d "$2" "$API_BASE/$1"
}

api_delete() {
    curl -fsS -K "$CURL_CFG" -X DELETE "$API_BASE/$1"
}

json_field() {
    # json_field <json> <field>  (best-effort: jq if present, else a grep/sed fallback for a flat string/id field)
    if [ "$HAVE_JQ" -eq 1 ]; then
        printf '%s' "$1" | jq -r ".$2 // empty"
    else
        printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1
    fi
}

if [ "$ACTION" = "remove" ]; then
    log "Looking up '$PLUGIN_NAME' on this tenant"
    PLUGINS_JSON="$(api_get v1/plugins)" || fail "could not list existing plugins on this tenant"
    REMOVE_PLUGIN_ID="$(printf '%s' "$PLUGINS_JSON" | jq -r --arg n "$PLUGIN_NAME" '.plugins[]? | select(.manifest.name==$n) | .id' | head -n1)"
    [ -n "$REMOVE_PLUGIN_ID" ] || fail "no plugin named '$PLUGIN_NAME' is registered on this tenant -- nothing to remove"

    printf 'Remove plugin "%s" (id %s) from this tenant? This does not delete Machines already created from it. [y/N] ' "$PLUGIN_NAME" "$REMOVE_PLUGIN_ID"
    read -r CONFIRM < "$TTY"
    case "$CONFIRM" in
        y|Y|yes|YES) ;;
        *) log "Cancelled, nothing removed"; exit 0 ;;
    esac

    run_quiet "Deleting plugin registration $REMOVE_PLUGIN_ID" \
        api_delete "v1/plugins/$REMOVE_PLUGIN_ID"

    printf '\nDone. "%s" (plugin id %s) has been removed from this tenant.\n' "$PLUGIN_NAME" "$REMOVE_PLUGIN_ID"
    exit 0
fi

# --- Step 1: patch the registry mirror so this VSat can pull ghcr.io -----

# The known-default registries.yaml shipped by Venafi's VSatellite, *without*
# the ghcr.io mirror. Only overwrite the customer's file if it matches this
# byte-for-byte -- if it's been customized in any other way, refuse rather
# than silently discard those customizations.
DEFAULT_REGISTRIES_NO_GHCR="$(mktemp)"
cat > "$DEFAULT_REGISTRIES_NO_GHCR" <<'YAML'
mirrors:
  "docker.io":
    endpoint:
      - "https://registry.venafi.cloud"
    rewrite:
      "^rancher/(.*)": "public/venafi-vsatellite/rancher/$1"
      "^bitnami/(.*)": "public/venafi-vsatellite/bitnami/$1"
  "public.ecr.aws":
    endpoint:
      - "https://registry.venafi.cloud"
    rewrite:
      "^knative/(.*)": "public/venafi-vsatellite/knative/$1"
      "^venafi-vsatellite/(.*)": "public/venafi-vsatellite/$1"
  "*":
    endpoint:
      - "https://registry.venafi.cloud"
YAML

TMP_REGISTRIES="$(mktemp)"
cat > "$TMP_REGISTRIES" <<'YAML'
mirrors:
  "docker.io":
    endpoint:
      - "https://registry.venafi.cloud"
    rewrite:
      "^rancher/(.*)": "public/venafi-vsatellite/rancher/$1"
      "^bitnami/(.*)": "public/venafi-vsatellite/bitnami/$1"
  "public.ecr.aws":
    endpoint:
      - "https://registry.venafi.cloud"
    rewrite:
      "^knative/(.*)": "public/venafi-vsatellite/knative/$1"
      "^venafi-vsatellite/(.*)": "public/venafi-vsatellite/$1"
  "ghcr.io":
    endpoint:
      - "https://ghcr.io"
    rewrite:
      "^(.*)": "$1"
  "*":
    endpoint:
      - "https://registry.venafi.cloud"
YAML

if [ -f "$REGISTRIES_FILE" ] && grep -q '"ghcr.io"' "$REGISTRIES_FILE" 2>/dev/null; then
    log "ghcr.io mirror already present in $REGISTRIES_FILE -- skipping registry patch"
    rm -f "$DEFAULT_REGISTRIES_NO_GHCR" "$TMP_REGISTRIES"
elif [ -f "$REGISTRIES_FILE" ] && ! diff -q "$REGISTRIES_FILE" "$DEFAULT_REGISTRIES_NO_GHCR" >/dev/null 2>&1; then
    rm -f "$DEFAULT_REGISTRIES_NO_GHCR" "$TMP_REGISTRIES"
    fail "$REGISTRIES_FILE doesn't match the expected default content -- it looks customized, so this script won't overwrite it. Add this block manually instead: $(cat <<'YAML'
  "ghcr.io":
    endpoint:
      - "https://ghcr.io"
    rewrite:
      "^(.*)": "$1"
YAML
)"
else
    rm -f "$DEFAULT_REGISTRIES_NO_GHCR"
    run_quiet "Backing up existing registry mirror config" \
        $SUDO sh -c "cp '$REGISTRIES_FILE' '$REGISTRIES_FILE.bak-$(date +%Y%m%d-%H%M%S)' 2>/dev/null || true"

    run_quiet "Writing ghcr.io registry mirror to $REGISTRIES_FILE (lets this VSat pull the plugin's public image)" \
        $SUDO sh -c "cp '$TMP_REGISTRIES' '$REGISTRIES_FILE' && chmod 644 '$REGISTRIES_FILE'"
    rm -f "$TMP_REGISTRIES"

    run_quiet "Restarting k3s to pick up the new registry mirror" \
        $SUDO systemctl restart k3s
    sleep 10
    run_quiet "Confirming k3s came back up" \
        $SUDO systemctl is-active --quiet k3s
    run_quiet "Rolling the satellite deployment so it re-reads the new mirror config" \
        $SUDO k3s kubectl rollout restart deployment/satellite -n satellite
fi

# --- Step 2: register the plugin -----------------------------------------

log "Checking whether '$PLUGIN_NAME' is already registered on this tenant"
PLUGINS_JSON="$(api_get v1/plugins)" || fail "could not list existing plugins on this tenant"
if [ "$HAVE_JQ" -eq 1 ]; then
    EXISTING_PLUGIN_ID="$(printf '%s' "$PLUGINS_JSON" | jq -r --arg n "$PLUGIN_NAME" '.plugins[]? | select(.manifest.name==$n) | .id' | head -n1)"
else
    EXISTING_PLUGIN_ID=""
fi

# Sentinel is split ("__MAN""IFEST_...") so a global sed of the contiguous
# assignment placeholder cannot rewrite this comparison and make the
# "not embedded" check always-true after publishing.
if [ "$MANIFEST_URL_PLACEHOLDER" = "__MAN""IFEST_JSON_BASE64__" ]; then
    fail "internal error: manifest content was not embedded into this script before publishing"
fi
MANIFEST_JSON="$(printf '%s' "$MANIFEST_URL_PLACEHOLDER" | base64 -d)"
# Public plugin API expects deployment nested under manifest (not a top-level
# sibling). Confirmed against existing MACHINE plugins and a live POST 201.
if [ "$HAVE_JQ" -eq 1 ]; then
    MANIFEST_JSON="$(printf '%s' "$MANIFEST_JSON" | jq -c --arg img "$PLUGIN_IMAGE" \
        '.deployment = {executionTarget: "vsat", image: $img}')" \
        || fail "failed to inject deployment into manifest JSON"
    PAYLOAD="$(printf '%s' "$MANIFEST_JSON" | jq -c '{pluginType: "MACHINE", manifest: .}')" \
        || fail "failed to build plugin registration payload"
else
    # No jq: strip outer braces and splice deployment in before the closing brace.
    MANIFEST_BODY="${MANIFEST_JSON#\{}"
    MANIFEST_BODY="${MANIFEST_BODY%\}}"
    MANIFEST_JSON="{${MANIFEST_BODY},\"deployment\":{\"executionTarget\":\"vsat\",\"image\":\"$PLUGIN_IMAGE\"}}"
    PAYLOAD="{\"pluginType\":\"MACHINE\",\"manifest\":$MANIFEST_JSON}"
fi

if [ -n "$EXISTING_PLUGIN_ID" ]; then
    log "Updating existing plugin registration (id $EXISTING_PLUGIN_ID) to point at the current image"
    RESPONSE="$(api_patch "v1/plugins/$EXISTING_PLUGIN_ID" "$PAYLOAD")" || fail "plugin update request failed"
    PLUGIN_ID="$EXISTING_PLUGIN_ID"
else
    log "Registering new plugin '$PLUGIN_NAME' against this tenant"
    RESPONSE="$(api_post v1/plugins "$PAYLOAD")" || fail "plugin registration request failed"
    PLUGIN_ID="$(json_field "$RESPONSE" id)"
    # Some regions return 201 with an empty body; fall back to a name lookup.
    if [ -z "$PLUGIN_ID" ]; then
        PLUGINS_JSON="$(api_get v1/plugins)" || fail "plugin create returned no id and re-list failed"
        if [ "$HAVE_JQ" -eq 1 ]; then
            PLUGIN_ID="$(printf '%s' "$PLUGINS_JSON" | jq -r --arg n "$PLUGIN_NAME" '.plugins[]? | select((.manifest.name // .name)==$n) | .id' | head -n1)"
        fi
    fi
fi

[ -n "$PLUGIN_ID" ] || fail "plugin registration did not return an id -- response: $RESPONSE"

# --- Step 3: confirm ------------------------------------------------------

log "Confirming plugin is visible on this tenant"
CONFIRM_JSON="$(api_get "v1/plugins/$PLUGIN_ID")" || fail "could not look up the newly-registered plugin ($PLUGIN_ID)"
CONFIRM_ID="$(json_field "$CONFIRM_JSON" id)"
[ "$CONFIRM_ID" = "$PLUGIN_ID" ] || fail "registered plugin $PLUGIN_ID did not come back on lookup"

printf '\nDone. "%s" is registered (plugin id %s) and this VSat can pull its image.\n' "$PLUGIN_NAME" "$PLUGIN_ID"
printf 'Next: in the Venafi Control Plane UI, go to Machines -> Add Machine, pick "%s",\nand enter your F5 device'"'"'s hostname/port/username/password.\n' "$PLUGIN_NAME"

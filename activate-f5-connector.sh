#!/bin/sh
# Registers the F5 BIG-IP device-cert-connector MACHINE plugin on this VSatellite:
# patches the local container registry mirror so this VSat can pull the plugin's
# public ghcr.io image, then registers the plugin against the caller's Venafi tenant.
#
# Usage: curl -fsSL <gist-raw-url>/activate-f5-connector.sh | sh -
#
# After this succeeds, add the actual F5 device as a Machine via the normal
# Venafi Control Plane UI (Machines -> Add Machine -> "F5 BIG-IP LTM Device
# Certificate") -- that part is standard product usage, not scripted here.

set -eu

PLUGIN_NAME="F5 BIG-IP LTM Device Certificate"
PLUGIN_IMAGE="ghcr.io/tall27/f5-device-cert-connector@sha256:5d0040bf49c482337600728466abc629d90ba25349cc9176da97235a8df24071"
REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"
TTY=/dev/tty

MANIFEST_URL_PLACEHOLDER="ewogICJuYW1lIjogIkY1IEJJRy1JUCBMVE0gRGV2aWNlIENlcnRpZmljYXRlIiwKICAiZGVzY3JpcHRpb24iOiAiRGlzY292ZXJzIGFuZCBwcm92aXNpb25zIHRoZSBGNSBCSUctSVAgbWFuYWdlbWVudCBHVUkgKGh0dHBkKSBUTFMgY2VydGlmaWNhdGUuIFNlcGFyYXRlIGZyb20gdGhlIGdlbmVyYWwgRjUgQklHLUlQIExUTSBjb25uZWN0b3IsIHdoaWNoIG1hbmFnZXMgdmlydHVhbC1zZXJ2ZXIgU1NMIHByb2ZpbGVzLiIsCiAgIndvcmtUeXBlcyI6IFsKICAgICJQUk9WSVNJT05JTkciLAogICAgIkRJU0NPVkVSWSIKICBdLAogICJwbHVnaW5UeXBlIjogIk1BQ0hJTkUiLAogICJkb21haW5TY2hlbWEiOiB7CiAgICAiYmluZGluZyI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgInRhcmdldCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAiZGVmYXVsdCI6ICJtYW5hZ2VtZW50LWludGVyZmFjZSIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJ0YXJnZXQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIsCiAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImJpbmRpbmcubGFiZWwiCiAgICB9LAogICAgImNvbm5lY3Rpb24iOiB7CiAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICJob3N0bmFtZU9yQWRkcmVzcyI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJhZGRyZXNzLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAwCiAgICAgICAgfSwKICAgICAgICAicG9ydCI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJwb3J0LmRlc2NyaXB0aW9uIiwKICAgICAgICAgICJtYXhpbXVtIjogNjU1MzUsCiAgICAgICAgICAibWluaW11bSI6IDEsCiAgICAgICAgICAidHlwZSI6ICJpbnRlZ2VyIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBvcnQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDEKICAgICAgICB9LAogICAgICAgICJ1c2VybmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1lbmNyeXB0ZWQiOiB0cnVlLAogICAgICAgICAgIngtbGFiZWxMb2NhbGl6YXRpb25LZXkiOiAidXNlcm5hbWUubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDIKICAgICAgICB9LAogICAgICAgICJwYXNzd29yZCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1jb250cm9sT3B0aW9ucyI6IHsKICAgICAgICAgICAgInBhc3N3b3JkIjogdHJ1ZSwKICAgICAgICAgICAgInNob3dQYXNzd29yZExhYmVsIjogInBhc3N3b3JkLnNob3dQYXNzd29yZCIsCiAgICAgICAgICAgICJoaWRlUGFzc3dvcmRMYWJlbCI6ICJwYXNzd29yZC5oaWRlUGFzc3dvcmQiCiAgICAgICAgICB9LAogICAgICAgICAgIngtZW5jcnlwdGVkIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBhc3N3b3JkLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAzCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImhvc3RuYW1lT3JBZGRyZXNzIiwKICAgICAgICAidXNlcm5hbWUiLAogICAgICAgICJwYXNzd29yZCIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJrZXlzdG9yZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJjZXJ0aWZpY2F0ZU5hbWUuZGVzY3JpcHRpb24iLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNlcnRpZmljYXRlTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMCwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9LAogICAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciLAogICAgICAgICAgIngtaGlkZGVuIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNoYWluTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMSwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJyZXF1aXJlZCI6IFsKICAgICAgICAiY2VydGlmaWNhdGVOYW1lIgogICAgICBdLAogICAgICAidHlwZSI6ICJvYmplY3QiLAogICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJrZXlzdG9yZS5sYWJlbCIsCiAgICAgICJ4LXByaW1hcnlLZXkiOiBbCiAgICAgICAgIiMvY2VydGlmaWNhdGVOYW1lIgogICAgICBdCiAgICB9LAogICAgImNlcnRpZmljYXRlQnVuZGxlIjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiY2VydGlmaWNhdGUiOiB7CiAgICAgICAgICAiY29udGVudEVuY29kaW5nIjogImJhc2U2NCIsCiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAiY2VydGlmaWNhdGVDaGFpbiI6IHsKICAgICAgICAgICJjb250ZW50RW5jb2RpbmciOiAiYmFzZTY0IiwKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9LAogICAgICAgICJwcml2YXRlS2V5IjogewogICAgICAgICAgImNvbnRlbnRFbmNvZGluZyI6ICJiYXNlNjQiLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWVuY3J5cHRlZC1iYXNlNjQiOiB0cnVlCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImNlcnRpZmljYXRlIiwKICAgICAgICAicHJpdmF0ZUtleSIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJtZXRhZGF0YSI6IHsKICAgICAgInR5cGUiOiAib2JqZWN0IiwKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9CiAgICAgIH0KICAgIH0sCiAgICAiZGlzY292ZXJ5IjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiZXhjbHVkZUV4cGlyZWRDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgICAidHlwZSI6ICJib29sZWFuIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImRpc2NvdmVyeS5leHBpcmVkQ2VydGlmaWNhdGVzTGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5Q29udHJvbCI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgIm1heFJlc3VsdHMiOiB7CiAgICAgICAgICAidHlwZSI6ICJpbnQiCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgIm1heFJlc3VsdHMiCiAgICAgIF0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5UGFnZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImRpc2NvdmVyeVR5cGUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAicGFnaW5hdG9yIjogewogICAgICAgICAgInR5cGUiOiAic3RyaW5nIgogICAgICAgIH0KICAgICAgfSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfQogIH0sCiAgImxvY2FsaXphdGlvblJlc291cmNlcyI6IHsKICAgICJlbiI6IHsKICAgICAgImFkZHJlc3MiOiB7CiAgICAgICAgImxhYmVsIjogIkY1IEJJRy1JUCBBZGRyZXNzL0hvc3RuYW1lIgogICAgICB9LAogICAgICAicG9ydCI6IHsKICAgICAgICAiZGVzY3JpcHRpb24iOiAiTm8gdmFsdWUgaXMgaW50ZXJwcmV0ZWQgYXMgNDQzIiwKICAgICAgICAibGFiZWwiOiAiUG9ydCIKICAgICAgfSwKICAgICAgInVzZXJuYW1lIjogewogICAgICAgICJsYWJlbCI6ICJVc2VybmFtZSIKICAgICAgfSwKICAgICAgInBhc3N3b3JkIjogewogICAgICAgICJsYWJlbCI6ICJQYXNzd29yZCIsCiAgICAgICAgInNob3dQYXNzd29yZCI6ICJTaG93IFBhc3N3b3JkIiwKICAgICAgICAiaGlkZVBhc3N3b3JkIjogIkhpZGUgUGFzc3dvcmQiCiAgICAgIH0sCiAgICAgICJrZXlzdG9yZSI6IHsKICAgICAgICAibGFiZWwiOiAiRGV2aWNlIENlcnRpZmljYXRlIEluZm9ybWF0aW9uIgogICAgICB9LAogICAgICAiY2VydGlmaWNhdGVOYW1lIjogewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJIb3cgdGhlIGNlcnRpZmljYXRlIHNob3VsZCBhcHBlYXIgb24gdGhlIEY1IEJJRy1JUCIsCiAgICAgICAgImxhYmVsIjogIkNlcnRpZmljYXRlIE5hbWUiCiAgICAgIH0sCiAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgImxhYmVsIjogIkNoYWluIEJ1bmRsZSBOYW1lIgogICAgICB9LAogICAgICAiYmluZGluZyI6IHsKICAgICAgICAibGFiZWwiOiAiTWFuYWdlbWVudCBJbnRlcmZhY2UiCiAgICAgIH0sCiAgICAgICJ0YXJnZXQiOiB7CiAgICAgICAgImxhYmVsIjogIlRhcmdldCIsCiAgICAgICAgImRlc2NyaXB0aW9uIjogIlRoZXJlIGlzIG9ubHkgb25lIHRhcmdldDogdGhlIEY1IG1hbmFnZW1lbnQgR1VJLiBObyBzZWxlY3Rpb24gbmVlZGVkLiIKICAgICAgfSwKICAgICAgImRpc2NvdmVyeSI6IHsKICAgICAgICAiZXhwaXJlZENlcnRpZmljYXRlc0xhYmVsIjogIkV4Y2x1ZGUgZXhwaXJlZCBjZXJ0aWZpY2F0ZXMiCiAgICAgIH0KICAgIH0KICB9LAogICJob29rcyI6IHsKICAgICJtYXBwaW5nIjogewogICAgICAiY29uZmlndXJlSW5zdGFsbGF0aW9uRW5kcG9pbnQiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2NvbmZpZ3VyZWluc3RhbGxhdGlvbmVuZHBvaW50IiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZGlzY292ZXJDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2Rpc2NvdmVyY2VydGlmaWNhdGVzIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZ2V0VGFyZ2V0Q29uZmlndXJhdGlvbiI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvZ2V0dGFyZ2V0Y29uZmlndXJhdGlvbiIsCiAgICAgICAgInJlcXVlc3QiOiBudWxsLAogICAgICAgICJyZXNwb25zZSI6IG51bGwKICAgICAgfSwKICAgICAgImluc3RhbGxDZXJ0aWZpY2F0ZUJ1bmRsZSI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvaW5zdGFsbGNlcnRpZmljYXRlYnVuZGxlIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAidGVzdENvbm5lY3Rpb24iOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL3Rlc3Rjb25uZWN0aW9uIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9CiAgICB9LAogICAgInJlcXVlc3RDb252ZXJ0ZXJzIjogWwogICAgICAiYXJndW1lbnRzLWRlY3J5cHRlciIKICAgIF0KICB9Cn0K"

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
require_cmd sudo
require_cmd sed

if command -v jq >/dev/null 2>&1; then
    HAVE_JQ=1
else
    HAVE_JQ=0
fi

if [ "$(id -u)" -eq 0 ]; then
    fail "run this as the regular VSat operator, not root -- it calls sudo itself only for the steps that need it"
fi

printf 'Venafi tenant API key: '
read -r API_KEY < "$TTY"
[ -n "$API_KEY" ] || fail "no API key entered"

API_BASE=""
for base in https://api.venafi.cloud https://api.eu.venafi.cloud https://api.au.venafi.cloud https://api.uk.venafi.cloud; do
    if curl -fsS -H "tppl-api-key: $API_KEY" "$base/v1/environments" >/dev/null 2>&1; then
        API_BASE="$base"
        break
    fi
done
[ -n "$API_BASE" ] || fail "could not reach Venafi TLS Protect Cloud with that API key in any region"

api_get() {
    curl -fsS -H "tppl-api-key: $API_KEY" "$API_BASE/$1"
}

api_post() {
    curl -fsS -H "tppl-api-key: $API_KEY" -H "Content-Type: application/json" -X POST -d "$2" "$API_BASE/$1"
}

api_patch() {
    curl -fsS -H "tppl-api-key: $API_KEY" -H "Content-Type: application/json" -X PATCH -d "$2" "$API_BASE/$1"
}

json_field() {
    # json_field <json> <field>  (best-effort: jq if present, else a grep/sed fallback for a flat string/id field)
    if [ "$HAVE_JQ" -eq 1 ]; then
        printf '%s' "$1" | jq -r ".$2 // empty"
    else
        printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1
    fi
}

# --- Step 1: patch the registry mirror so this VSat can pull ghcr.io -----

if [ -f "$REGISTRIES_FILE" ] && grep -q '"ghcr.io"' "$REGISTRIES_FILE" 2>/dev/null; then
    log "ghcr.io mirror already present in $REGISTRIES_FILE -- skipping registry patch"
elif [ -f "$REGISTRIES_FILE" ] && ! grep -q '^mirrors:' "$REGISTRIES_FILE" 2>/dev/null; then
    fail "$REGISTRIES_FILE exists but doesn't match the expected default shape -- add a ghcr.io mirror block manually, this script won't overwrite a customized file"
else
    run_quiet "Backing up existing registry mirror config" \
        sudo sh -c "cp '$REGISTRIES_FILE' '$REGISTRIES_FILE.bak-$(date +%Y%m%d-%H%M%S)' 2>/dev/null || true"

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

    run_quiet "Writing ghcr.io registry mirror to $REGISTRIES_FILE (lets this VSat pull the plugin's public image)" \
        sudo sh -c "cp '$TMP_REGISTRIES' '$REGISTRIES_FILE' && chmod 644 '$REGISTRIES_FILE'"
    rm -f "$TMP_REGISTRIES"

    run_quiet "Restarting k3s to pick up the new registry mirror" \
        sudo systemctl restart k3s
    sleep 10
    run_quiet "Confirming k3s came back up" \
        sudo systemctl is-active --quiet k3s
    run_quiet "Rolling the satellite deployment so it re-reads the new mirror config" \
        sudo k3s kubectl rollout restart deployment/satellite -n satellite
fi

# --- Step 2: register the plugin -----------------------------------------

log "Checking whether '$PLUGIN_NAME' is already registered on this tenant"
PLUGINS_JSON="$(api_get v1/plugins)"
if [ "$HAVE_JQ" -eq 1 ]; then
    EXISTING_PLUGIN_ID="$(printf '%s' "$PLUGINS_JSON" | jq -r --arg n "$PLUGIN_NAME" '.plugins[]? | select(.manifest.name==$n) | .id' | head -n1)"
else
    EXISTING_PLUGIN_ID=""
fi

case "$MANIFEST_URL_PLACEHOLDER" in
    ewogICJuYW1lIjogIkY1IEJJRy1JUCBMVE0gRGV2aWNlIENlcnRpZmljYXRlIiwKICAiZGVzY3JpcHRpb24iOiAiRGlzY292ZXJzIGFuZCBwcm92aXNpb25zIHRoZSBGNSBCSUctSVAgbWFuYWdlbWVudCBHVUkgKGh0dHBkKSBUTFMgY2VydGlmaWNhdGUuIFNlcGFyYXRlIGZyb20gdGhlIGdlbmVyYWwgRjUgQklHLUlQIExUTSBjb25uZWN0b3IsIHdoaWNoIG1hbmFnZXMgdmlydHVhbC1zZXJ2ZXIgU1NMIHByb2ZpbGVzLiIsCiAgIndvcmtUeXBlcyI6IFsKICAgICJQUk9WSVNJT05JTkciLAogICAgIkRJU0NPVkVSWSIKICBdLAogICJwbHVnaW5UeXBlIjogIk1BQ0hJTkUiLAogICJkb21haW5TY2hlbWEiOiB7CiAgICAiYmluZGluZyI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgInRhcmdldCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAiZGVmYXVsdCI6ICJtYW5hZ2VtZW50LWludGVyZmFjZSIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJ0YXJnZXQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIsCiAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImJpbmRpbmcubGFiZWwiCiAgICB9LAogICAgImNvbm5lY3Rpb24iOiB7CiAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICJob3N0bmFtZU9yQWRkcmVzcyI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJhZGRyZXNzLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAwCiAgICAgICAgfSwKICAgICAgICAicG9ydCI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJwb3J0LmRlc2NyaXB0aW9uIiwKICAgICAgICAgICJtYXhpbXVtIjogNjU1MzUsCiAgICAgICAgICAibWluaW11bSI6IDEsCiAgICAgICAgICAidHlwZSI6ICJpbnRlZ2VyIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBvcnQubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDEKICAgICAgICB9LAogICAgICAgICJ1c2VybmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1lbmNyeXB0ZWQiOiB0cnVlLAogICAgICAgICAgIngtbGFiZWxMb2NhbGl6YXRpb25LZXkiOiAidXNlcm5hbWUubGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDIKICAgICAgICB9LAogICAgICAgICJwYXNzd29yZCI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAieC1jb250cm9sT3B0aW9ucyI6IHsKICAgICAgICAgICAgInBhc3N3b3JkIjogdHJ1ZSwKICAgICAgICAgICAgInNob3dQYXNzd29yZExhYmVsIjogInBhc3N3b3JkLnNob3dQYXNzd29yZCIsCiAgICAgICAgICAgICJoaWRlUGFzc3dvcmRMYWJlbCI6ICJwYXNzd29yZC5oaWRlUGFzc3dvcmQiCiAgICAgICAgICB9LAogICAgICAgICAgIngtZW5jcnlwdGVkIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogInBhc3N3b3JkLmxhYmVsIiwKICAgICAgICAgICJ4LXJhbmsiOiAzCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImhvc3RuYW1lT3JBZGRyZXNzIiwKICAgICAgICAidXNlcm5hbWUiLAogICAgICAgICJwYXNzd29yZCIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJrZXlzdG9yZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJjZXJ0aWZpY2F0ZU5hbWUuZGVzY3JpcHRpb24iLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNlcnRpZmljYXRlTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMCwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9LAogICAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciLAogICAgICAgICAgIngtaGlkZGVuIjogdHJ1ZSwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImNoYWluTmFtZS5sYWJlbCIsCiAgICAgICAgICAieC1yYW5rIjogMSwKICAgICAgICAgICJwYXR0ZXJuIjogIl5bXFx3XFxkXFwtLl0rJCIKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJyZXF1aXJlZCI6IFsKICAgICAgICAiY2VydGlmaWNhdGVOYW1lIgogICAgICBdLAogICAgICAidHlwZSI6ICJvYmplY3QiLAogICAgICAieC1sYWJlbExvY2FsaXphdGlvbktleSI6ICJrZXlzdG9yZS5sYWJlbCIsCiAgICAgICJ4LXByaW1hcnlLZXkiOiBbCiAgICAgICAgIiMvY2VydGlmaWNhdGVOYW1lIgogICAgICBdCiAgICB9LAogICAgImNlcnRpZmljYXRlQnVuZGxlIjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiY2VydGlmaWNhdGUiOiB7CiAgICAgICAgICAiY29udGVudEVuY29kaW5nIjogImJhc2U2NCIsCiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAiY2VydGlmaWNhdGVDaGFpbiI6IHsKICAgICAgICAgICJjb250ZW50RW5jb2RpbmciOiAiYmFzZTY0IiwKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9LAogICAgICAgICJwcml2YXRlS2V5IjogewogICAgICAgICAgImNvbnRlbnRFbmNvZGluZyI6ICJiYXNlNjQiLAogICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICJ4LWVuY3J5cHRlZC1iYXNlNjQiOiB0cnVlCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgImNlcnRpZmljYXRlIiwKICAgICAgICAicHJpdmF0ZUtleSIKICAgICAgXSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfSwKICAgICJtZXRhZGF0YSI6IHsKICAgICAgInR5cGUiOiAib2JqZWN0IiwKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImNlcnRpZmljYXRlTmFtZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICB9CiAgICAgIH0KICAgIH0sCiAgICAiZGlzY292ZXJ5IjogewogICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAiZXhjbHVkZUV4cGlyZWRDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgICAidHlwZSI6ICJib29sZWFuIiwKICAgICAgICAgICJ4LWxhYmVsTG9jYWxpemF0aW9uS2V5IjogImRpc2NvdmVyeS5leHBpcmVkQ2VydGlmaWNhdGVzTGFiZWwiLAogICAgICAgICAgIngtcmFuayI6IDAKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5Q29udHJvbCI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgIm1heFJlc3VsdHMiOiB7CiAgICAgICAgICAidHlwZSI6ICJpbnQiCiAgICAgICAgfQogICAgICB9LAogICAgICAicmVxdWlyZWQiOiBbCiAgICAgICAgIm1heFJlc3VsdHMiCiAgICAgIF0sCiAgICAgICJ0eXBlIjogIm9iamVjdCIKICAgIH0sCiAgICAiZGlzY292ZXJ5UGFnZSI6IHsKICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgImRpc2NvdmVyeVR5cGUiOiB7CiAgICAgICAgICAidHlwZSI6ICJzdHJpbmciCiAgICAgICAgfSwKICAgICAgICAicGFnaW5hdG9yIjogewogICAgICAgICAgInR5cGUiOiAic3RyaW5nIgogICAgICAgIH0KICAgICAgfSwKICAgICAgInR5cGUiOiAib2JqZWN0IgogICAgfQogIH0sCiAgImxvY2FsaXphdGlvblJlc291cmNlcyI6IHsKICAgICJlbiI6IHsKICAgICAgImFkZHJlc3MiOiB7CiAgICAgICAgImxhYmVsIjogIkY1IEJJRy1JUCBBZGRyZXNzL0hvc3RuYW1lIgogICAgICB9LAogICAgICAicG9ydCI6IHsKICAgICAgICAiZGVzY3JpcHRpb24iOiAiTm8gdmFsdWUgaXMgaW50ZXJwcmV0ZWQgYXMgNDQzIiwKICAgICAgICAibGFiZWwiOiAiUG9ydCIKICAgICAgfSwKICAgICAgInVzZXJuYW1lIjogewogICAgICAgICJsYWJlbCI6ICJVc2VybmFtZSIKICAgICAgfSwKICAgICAgInBhc3N3b3JkIjogewogICAgICAgICJsYWJlbCI6ICJQYXNzd29yZCIsCiAgICAgICAgInNob3dQYXNzd29yZCI6ICJTaG93IFBhc3N3b3JkIiwKICAgICAgICAiaGlkZVBhc3N3b3JkIjogIkhpZGUgUGFzc3dvcmQiCiAgICAgIH0sCiAgICAgICJrZXlzdG9yZSI6IHsKICAgICAgICAibGFiZWwiOiAiRGV2aWNlIENlcnRpZmljYXRlIEluZm9ybWF0aW9uIgogICAgICB9LAogICAgICAiY2VydGlmaWNhdGVOYW1lIjogewogICAgICAgICJkZXNjcmlwdGlvbiI6ICJIb3cgdGhlIGNlcnRpZmljYXRlIHNob3VsZCBhcHBlYXIgb24gdGhlIEY1IEJJRy1JUCIsCiAgICAgICAgImxhYmVsIjogIkNlcnRpZmljYXRlIE5hbWUiCiAgICAgIH0sCiAgICAgICJjaGFpbk5hbWUiOiB7CiAgICAgICAgImxhYmVsIjogIkNoYWluIEJ1bmRsZSBOYW1lIgogICAgICB9LAogICAgICAiYmluZGluZyI6IHsKICAgICAgICAibGFiZWwiOiAiTWFuYWdlbWVudCBJbnRlcmZhY2UiCiAgICAgIH0sCiAgICAgICJ0YXJnZXQiOiB7CiAgICAgICAgImxhYmVsIjogIlRhcmdldCIsCiAgICAgICAgImRlc2NyaXB0aW9uIjogIlRoZXJlIGlzIG9ubHkgb25lIHRhcmdldDogdGhlIEY1IG1hbmFnZW1lbnQgR1VJLiBObyBzZWxlY3Rpb24gbmVlZGVkLiIKICAgICAgfSwKICAgICAgImRpc2NvdmVyeSI6IHsKICAgICAgICAiZXhwaXJlZENlcnRpZmljYXRlc0xhYmVsIjogIkV4Y2x1ZGUgZXhwaXJlZCBjZXJ0aWZpY2F0ZXMiCiAgICAgIH0KICAgIH0KICB9LAogICJob29rcyI6IHsKICAgICJtYXBwaW5nIjogewogICAgICAiY29uZmlndXJlSW5zdGFsbGF0aW9uRW5kcG9pbnQiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2NvbmZpZ3VyZWluc3RhbGxhdGlvbmVuZHBvaW50IiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZGlzY292ZXJDZXJ0aWZpY2F0ZXMiOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL2Rpc2NvdmVyY2VydGlmaWNhdGVzIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAiZ2V0VGFyZ2V0Q29uZmlndXJhdGlvbiI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvZ2V0dGFyZ2V0Y29uZmlndXJhdGlvbiIsCiAgICAgICAgInJlcXVlc3QiOiBudWxsLAogICAgICAgICJyZXNwb25zZSI6IG51bGwKICAgICAgfSwKICAgICAgImluc3RhbGxDZXJ0aWZpY2F0ZUJ1bmRsZSI6IHsKICAgICAgICAicGF0aCI6ICIvdjEvaW5zdGFsbGNlcnRpZmljYXRlYnVuZGxlIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9LAogICAgICAidGVzdENvbm5lY3Rpb24iOiB7CiAgICAgICAgInBhdGgiOiAiL3YxL3Rlc3Rjb25uZWN0aW9uIiwKICAgICAgICAicmVxdWVzdCI6IG51bGwsCiAgICAgICAgInJlc3BvbnNlIjogbnVsbAogICAgICB9CiAgICB9LAogICAgInJlcXVlc3RDb252ZXJ0ZXJzIjogWwogICAgICAiYXJndW1lbnRzLWRlY3J5cHRlciIKICAgIF0KICB9Cn0K) fail "internal error: manifest content was not embedded into this script before publishing" ;;
esac
MANIFEST_JSON="$(printf '%s' "$MANIFEST_URL_PLACEHOLDER" | base64 -d)"
DEPLOYMENT_JSON="{\"executionTarget\":\"vsat\",\"image\":\"$PLUGIN_IMAGE\"}"
PAYLOAD="{\"pluginType\":\"MACHINE\",\"manifest\":$MANIFEST_JSON,\"deployment\":$DEPLOYMENT_JSON}"

if [ -n "$EXISTING_PLUGIN_ID" ]; then
    log "Updating existing plugin registration (id $EXISTING_PLUGIN_ID) to point at the current image"
    RESPONSE="$(api_patch "v1/plugins/$EXISTING_PLUGIN_ID" "$PAYLOAD")" || fail "plugin update request failed"
    PLUGIN_ID="$EXISTING_PLUGIN_ID"
else
    log "Registering new plugin '$PLUGIN_NAME' against this tenant"
    RESPONSE="$(api_post v1/plugins "$PAYLOAD")" || fail "plugin registration request failed"
    PLUGIN_ID="$(json_field "$RESPONSE" id)"
fi

[ -n "$PLUGIN_ID" ] || fail "plugin registration did not return an id -- response: $RESPONSE"

# --- Step 3: confirm ------------------------------------------------------

log "Confirming plugin is visible on this tenant"
CONFIRM_JSON="$(api_get "v1/plugins/$PLUGIN_ID")"
CONFIRM_ID="$(json_field "$CONFIRM_JSON" id)"
[ "$CONFIRM_ID" = "$PLUGIN_ID" ] || fail "registered plugin $PLUGIN_ID did not come back on lookup"

printf '\nDone. "%s" is registered (plugin id %s) and this VSat can pull its image.\n' "$PLUGIN_NAME" "$PLUGIN_ID"
printf 'Next: in the Venafi Control Plane UI, go to Machines -> Add Machine, pick "%s",\nand enter your F5 device'"'"'s hostname/port/username/password.\n' "$PLUGIN_NAME"

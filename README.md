# venafi-connector-activation

Single-command activation scripts for Venafi VaaS MACHINE connector plugins. Each connector gets
its own subfolder with one `activate.sh`.

## F5 BIG-IP device-cert-connector

Run on the target VSatellite (needs `sudo`, `curl`; prompts for your Venafi tenant API key):

```sh
curl -fsSL https://tinyurl.com/28tp3kbb | sh -
```

(equivalent full URL: `https://raw.githubusercontent.com/tall27/venafi-connector-activation/main/f5-device-cert-connector/activate.sh`)

What it does: patches the VSat's container registry mirror so it can pull the connector's public
ghcr.io image, restarts k3s/satellite to pick that up, then registers the plugin against your
tenant. Afterward, add the actual F5 device as a Machine via the normal Venafi Control Plane UI
(Machines -> Add Machine -> "F5 BIG-IP LTM Device Certificate").

### Other commands

```sh
curl -fsSL https://tinyurl.com/28tp3kbb | sh -s -- --help     # show usage
curl -fsSL https://tinyurl.com/28tp3kbb | sh -s -- --remove   # remove the plugin registration
```

`--remove` deregisters the plugin from the tenant (asks for confirmation first). It does not
delete any Machines already created from it, and does not revert the registry mirror patch.

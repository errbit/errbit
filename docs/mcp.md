# Errbit MCP Server

## Configure server

To configure the Errbit MCP Server, you need to set up the following environment variable:

`ERRBIT_MCP_SERVER` to `true`.

By default, MCP Server is disabled.

## Configure client

```toml
[mcp_servers.errbit]
url = "http://localhost:3000/mcp"
```

Make sure to replace `http://localhost:3000/mcp` with the actual URL of your Errbit Server.

## Available tools

### Get apps

`errbit_list_apps`

### Get app details

`errbit_get_app`

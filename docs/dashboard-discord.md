# Discord Module

The `discord` module fetches and displays the number of online members in a specified Discord server.

## How it Works

This module uses the public Discord widget JSON API. For the module to work, the target server must have the public widget enabled.

You can enable this in your server's settings: `Server Settings` > `Widget`. Make sure the "Enable server widget" option is checked.

## Configuration

To use this module, you must provide your Discord Server ID in the `DISCORD_SERVER_ID` variable in your `config/config.sh` file.

### Finding Your Server ID

If you are the server owner, you can find the Server ID in the same `Widget` settings page.

If you are not the owner, you can find the ID by enabling "Developer Mode" in your Discord user settings (`User Settings` > `Advanced`), and then right-clicking on the server icon and selecting "Copy Server ID".

```bash
# Example
DISCORD_SERVER_ID="1400382194509287426"
```

If the `DISCORD_SERVER_ID` is not provided, or if the widget is not enabled for the given ID, this module will be skipped and will not appear in the report.

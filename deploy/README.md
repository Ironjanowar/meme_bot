# Deploy on Coco

The service runs as the `cuwano` user, uses a Mix release, and stores its SQLite database outside the source checkout.

## Paths

- Source and release: `~/apps/meme_bot`
- Private environment: `~/.config/meme_cache_bot/env` (`0600`)
- SQLite database: `~/.local/share/meme_cache_bot/meme_cache.db` (`0600`)
- Release runtime files: `$XDG_RUNTIME_DIR/meme_cache_bot` (created privately by systemd)
- Unit: `~/.config/systemd/user/meme-cache-bot.service`

## Private environment

Create the directory with mode `0700` and the environment file with mode `0600`. Never commit this file.

```dotenv
BOT_TOKEN=<telegram token>
ADMINS=[]
DATABASE_PATH=/home/cuwano/.local/share/meme_cache_bot/meme_cache.db
```

`ADMINS` is a JSON array of numeric Telegram user IDs.

## Build and initialize

Run these commands from the merged `master` checkout:

```bash
umask 077
install -d -m 700 "$HOME/.config/meme_cache_bot" "$HOME/.local/share/meme_cache_bot"
set -a
. "$HOME/.config/meme_cache_bot/env"
set +a

export MIX_ENV=prod
export PATH="$HOME/.local/bin:$PATH"
mise install
mise exec -- mix local.hex --force
mise exec -- mix local.rebar --force
mise exec -- mix deps.get --only prod
mise exec -- mix compile --warnings-as-errors
mise exec -- mix ecto.create
mise exec -- mix ecto.migrate
chmod 600 "$DATABASE_PATH"
mise exec -- mix release --overwrite
```

`mise` installs under `~/.local/bin`, which is not on `PATH` in non-interactive SSH shells. Use `mise exec -- mix ...` rather than `mix ...` here: `mise install` alone does not put `mix` on `PATH`, and a missing `mix` fails the build.

## Install and start the service

```bash
install -m 600 deploy/meme-cache-bot.service "$HOME/.config/systemd/user/meme-cache-bot.service"
systemctl --user daemon-reload
systemctl --user enable --now meme-cache-bot.service
systemctl --user status meme-cache-bot.service
journalctl --user -u meme-cache-bot.service -n 100 --no-pager
```

Verify that user lingering is enabled so the service survives logout and boot:

```bash
loginctl show-user "$USER" -p Linger
```

## Operations

```bash
systemctl --user restart meme-cache-bot.service
systemctl --user stop meme-cache-bot.service
journalctl --user -u meme-cache-bot.service -f
```

Stop the service before copying the SQLite file. WAL data may otherwise remain in `meme_cache.db-wal`.

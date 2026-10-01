# MemeCacheBot

## Use of the `@meme_cache_bot`

Just start a conversation with `@meme_cache_bot` in Telegram.

Send a meme in any of these formats:
 - Sticker
 - GIF
 - Photo
 - Video

If you don't have the meme saved, the bot will ask if you want to save it
![Save Button](./docs/images/save_button.png)

If you have the meme saved, the bot shows its current personal tags and lets you delete it or choose **Edit tags**.
Tags are private to your copy of the meme. Send 1–20 one-word tags, separated by commas; tags are normalized to lowercase and replace the previous list.
![Delete Button](./docs/images/delete_button.png)

Once you have a meme saved, use the bot inline. Write `@meme_cache_bot` in any chat to show your cached memes, or add one or more tags separated by spaces or commas to search. A multi-tag search matches any supplied tag (OR) and never returns another user's memes.

<img src="./docs/images/use_inline.jpg" width="400">

### Pagination

If you have more than 50 memes you'll have more than one page of memes, write the number of the page you want to see after the bot name. For example: `@meme_cache_bot 2`

![Pagination](./docs/images/pagination.jpg)

## Deploy your own meme bot

MemeCacheBot requires Erlang 29.1.1 and Elixir 1.20.4 (pinned in `.tool-versions`). It uses SQLite; no PostgreSQL server is required.

1. Export the required environment variables:
   - `BOT_TOKEN`: Telegram bot token.
   - `ADMINS`: JSON array of numeric Telegram user IDs, for example `[]`.
   - `DATABASE_PATH`: required in production; path to the SQLite database.
2. Install dependencies and initialize the database with `make db_setup`.
3. Run locally with `make iex`, or build a production release with `make release`.

For the hardened `systemd --user` deployment used on Coco, see [`deploy/README.md`](deploy/README.md). Production logs are written to journald and can be read with:

```bash
journalctl --user -u meme-cache-bot.service -f
```

This release intentionally starts with a fresh SQLite database; it does not migrate existing PostgreSQL data.

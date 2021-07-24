defmodule MemeCacheBot.Bot do
  @bot :meme_cache_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("help", description: "Print the bot's help")
  command("about", description: "Who made this bot?")
  command("count", description: "How many memes have you saved?")

  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(MemeCacheBot.Middlewares.RegisterUser)

  alias MemeCacheBot.Utils

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, Utils.help_command())
  end

  def handle({:command, :about, _msg}, context) do
    answer(context, Utils.about_command(), parse_mode: "Markdown")
  end

  def handle({:command, :count, %{from: %{id: telegram_id}}}, context) do
    message = MemeCacheBot.count_memes(telegram_id)
    answer(context, message, parse_mode: "Markdown")
  end
end

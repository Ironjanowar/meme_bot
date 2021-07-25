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

  alias MemeCacheBot.MessageFormatter
  alias MemeCacheBot.Utils

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :help, _msg}, context) do
    {message, opts} = MessageFormatter.help_command()
    answer(context, message, opts)
  end

  def handle({:command, :about, _msg}, context) do
    {message, opts} = MessageFormatter.about_command()
    answer(context, message, opts)
  end

  def handle({:command, :count, %{from: %{id: telegram_id}}}, context) do
    {message, opts} = MemeCacheBot.count_memes(telegram_id)
    answer(context, message, opts)
  end

  def handle({:message, message}, context) do
    {message, opts} = MemeCacheBot.process_message(message)
    answer(context, message, opts)
  end

  def handle({:callback_query, %{data: uuid, from: from, message: message}}, context) do
    {message, opts} = MemeCacheBot.apply_meme_action(uuid, from, message)
    edit(context, :inline, message, opts)
  end

  def handle({:inline_query, %{query: text, from: from}}, context) do
    {articles, opts} = MemeCacheBot.get_meme_articles(text, from)
    answer_inline_query(context, articles, opts)
  end

  def handle({:update, %{chosen_inline_result: message}}, _) do
    MemeCacheBot.update_last_used(message)
  end

  # Admins only
  def handle({:command, "stats", %{from: %{id: telegram_id}}}, context) do
    if Utils.is_admin(telegram_id) do
      {message, opts} = MemeCacheBot.get_stats()
      answer(context, message, opts)
    end
  end

  def handle(_, _), do: :ignore
  def handle(_), do: :ignore
end

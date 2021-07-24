defmodule MemeCacheBot.Utils do
  def help_command do
    """
    Send me a meme in any of these formats:
     - Sticker
     - GIF
     - Photo
     - Video

    If you don't have it, I'll ask if you want to save it!

    If you already have that meme, I'll ask if you want to delete it.
    """
  end

  def about_command do
    """
    __This bot was made by [@Ironjanowar](https://github.com/Ironjanowar) with ❤️__

    If you want to share some love and give a star ⭐️ to the repo [here it is](https://github.com/Ironjanowar/meme_bot)
    """
  end
end

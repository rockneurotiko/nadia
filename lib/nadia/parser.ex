defmodule Nadia.Parser do
  @moduledoc """
  Provides parser logics for API results.
  """

  alias Nadia.User
  alias Nadia.GroupChat
  alias Nadia.Message
  alias Nadia.PhotoSize
  alias Nadia.Audio
  alias Nadia.Document
  alias Nadia.Sticker
  alias Nadia.Video
  alias Nadia.Voice
  alias Nadia.Contact
  alias Nadia.Location
  alias Nadia.Update
  alias Nadia.UserProfilePhotos

  @doc """
  parse from the API response json.
  """
  def parse_result(result, method) do
    case method do
      "getMe" -> struct(User, result)
      "sendChatAction" -> result
      "getUserProfilePhotos" -> parse_user_profile_photos(result)
      "getUpdates" -> parse_updates(result)
      "setWebhook" -> result
      _ -> parse_message(result)
    end
  end

  defp parse_message(message) do
    message = struct(Message, message)
    from = struct(User, message.from)
    chat = if Dict.has_key?(message.chat, :title) do
      struct(GroupChat, message.chat)
    else
      struct(User, message.chat)
    end
    message = %{message | from: from, chat: chat}

    if message.forward_from do
      message = %{message | forward_from: struct(User, message.forward_from)}
    end
    if message.reply_to_message do
      message = %{message | reply_to_message: parse_message(message.reply_to_message)}
    end
    if message.audio do
      message = %{message | audio: struct(Audio, message.audio)}
    end
    if message.document do
      message = %{message | document: parse_document(message.document)}
    end
    if message.photo do
      photo = for photo_size <- message.photo, do: struct(PhotoSize, photo_size)
      message = %{message | photo: photo}
    end
    if message.sticker do
      message = %{message | sticker: parse_sticker(message.sticker)}
    end
    if message.video do
      message = %{message | video: parse_video(message.video)}
    end
    if message.voice do
      message = %{message | voice: struct(Voice, message.voice)}
    end
    if message.contact do
      message = %{message | contact: struct(Contact, message.contact)}
    end
    if message.location do
      message = %{message | location: struct(Location, message.location)}
    end
    if message.new_chat_participant do
      message = %{message | new_chat_participant: struct(User, message.new_chat_participant)}
    end
    if message.left_chat_participant do
      message = %{message | left_chat_participant: struct(User, message.left_chat_participant)}
    end
    if message.new_chat_photo do
      new_chat_photo = for photo_size <- message.new_chat_photo, do: struct(PhotoSize, photo_size)
      message = %{message | new_chat_photo: new_chat_photo}
    end

    message
  end

  defp parse_document(document) do
    document = struct(Document, document)
    %{document | thumb: struct(PhotoSize, document.thumb)}
  end

  defp parse_sticker(sticker) do
    sticker = struct(Sticker, sticker)
    %{sticker | thumb: struct(PhotoSize, sticker.thumb)}
  end

  defp parse_video(video) do
    video = struct(Video, video)
    %{video | thumb: struct(PhotoSize, video.thumb)}
  end

  defp parse_user_profile_photos(user_profile_photos) do
    user_profile_photos = struct(UserProfilePhotos, user_profile_photos)
    photos = for photo <- user_profile_photos.photos do
      for photo_size <- photo, do: struct(PhotoSize, photo_size)
    end
    %{user_profile_photos | photos: photos}
  end

  defp parse_updates(updates) do
    for update <- updates do
      update = struct(Update, update)
      if update.message do
        update = %{update | message: parse_message(update.message)}
      end
      update
    end
  end

end
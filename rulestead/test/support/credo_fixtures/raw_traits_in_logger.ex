defmodule Rulestead.CredoFixtures.RawTraitsInLogger do
  require Logger

  def log do
    Logger.metadata(email: "person@example.com", ip: "127.0.0.1", request_id: "req-123")
  end
end

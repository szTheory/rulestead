defmodule Rulestead.CredoFixtures.SocketCapturedInAsync do
  def update(assigns, socket) do
    start_async(socket, :load_actor, fn ->
      {assigns, socket.assigns.actor}
    end)

    {:ok, socket}
  end

  defp start_async(_socket, _name, fun), do: fun.()
end

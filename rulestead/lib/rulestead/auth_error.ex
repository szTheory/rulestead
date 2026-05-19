defmodule Rulestead.AuthError do
  @moduledoc false
  # Constructors for auth-domain `Rulestead.Error` values.

  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :auth,
          type: type,
          message: message
        ],
        opts
      )
    )
  end

  @spec unauthorized(keyword()) :: Error.t()
  def unauthorized(opts \\ []) do
    new(:unauthorized, "caller is not authorized to perform this action", opts)
  end
end

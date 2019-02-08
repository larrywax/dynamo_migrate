defmodule DynamoMigrate.Repo.NewFiscalCode do
  @moduledoc false

  @type t :: %__MODULE__{}

  @derive [ExAws.Dynamo.Encodable]
  defstruct [:hash, :fiscal_code, :record_type, :content, :timestamp_ttl]
end

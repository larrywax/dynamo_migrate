defmodule DynamoMigrate.Repo.OldFiscalCode do
  @moduledoc false

  @type t :: %__MODULE__{}

  @derive [ExAws.Dynamo.Encodable]
  defstruct [:id, :fiscal_code, :record_type, :content, :timestamp_ttl]
end

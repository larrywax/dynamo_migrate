defmodule DynamoMigrate.Repo.NewPlateNumber do
  @moduledoc false

  @type t :: %__MODULE__{}

  @derive [ExAws.Dynamo.Encodable]
  defstruct [:hash, :plate_number, :record_type, :content, :timestamp_ttl]
end

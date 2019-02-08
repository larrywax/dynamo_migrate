defmodule DynamoMigrate.Repo.OldPlateNumber do
  @moduledoc false

  @type t :: %__MODULE__{}

  @derive [ExAws.Dynamo.Encodable]
  defstruct [:id, :plate_number, :record_type, :content, :timestamp_ttl]
end

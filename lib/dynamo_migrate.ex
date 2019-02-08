defmodule DynamoMigrate do
  alias ExAws.Dynamo
  alias DynamoMigrate.Repo
  alias DynamoMigrate.Repo.OldPlateNumber

  @old_plate_number_table Application.get_env(:dynamo_migrate, :dynamo_db)[
                            :old_plate_number_table
                          ]

  def run do
    @old_plate_number_table
    |> Dynamo.scan(limit: 1)
    |> ExAws.request!()
    |> Repo.parse_result(OldPlateNumber)
    |> Enum.each(fn rec ->
        Repo.convert_record(rec)
        |> IO.inspect()
      end)
  end
end

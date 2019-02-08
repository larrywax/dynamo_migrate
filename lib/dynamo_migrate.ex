defmodule DynamoMigrate do
  require Logger
  alias ExAws.Dynamo
  alias DynamoMigrate.Repo
  alias DynamoMigrate.Repo.OldPlateNumber
  alias DynamoMigrate.Repo.OldFiscalCode

  @old_plate_number_table Application.get_env(:dynamo_migrate, :old_plate_number_table)
  @old_fiscal_code_table Application.get_env(:dynamo_migrate, :old_fiscal_code_table)

  def run do
    # Logger.info("Start plate number table import")
    #
    # @old_plate_number_table
    # |> Dynamo.scan(limit: 100)
    # |> ExAws.request!()
    # |> Repo.parse_result(OldPlateNumber)
    # |> Enum.map(&Repo.convert_record/1)
    # |> Enum.map(&Repo.insert(Application.get_env(:dynamo_migrate, :new_plate_number_table), &1))
    #
    # Logger.info("Plate number table import completed!")

    Logger.info("Start fiscal code table import")

    @old_fiscal_code_table
    |> Dynamo.scan(limit: 100)
    |> ExAws.request!()
    |> Repo.parse_result(OldFiscalCode)
    |> Enum.map(&Repo.convert_record/1)
    |> Enum.map(&Repo.insert(Application.get_env(:dynamo_migrate, :new_fiscal_code_table), &1))

    Logger.info("Fiscal code table import completed!")
  end
end

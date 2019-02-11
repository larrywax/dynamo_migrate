defmodule DynamoMigrate do
  require Logger
  require GenServer

  alias ExAws.Dynamo

  @old_plate_number_table Application.get_env(:dynamo_migrate, :old_plate_number_table)
  @old_fiscal_code_table Application.get_env(:dynamo_migrate, :old_fiscal_code_table)

  def run do
    Logger.info("Start plate number table import")

    {:ok, pid} = GenServer.start_link(DynamoMigrate.Writer, [])

    case scan(@old_plate_number_table, pid) do
      :ok -> Logger.info("Completed!")
      :error -> Logger.error("ERROR")
    end

    # |> Dynamo.scan()
    # |> ExAws.request!()
    # |> Repo.parse_result(OldPlateNumber)
    # |> Enum.map(&Repo.convert_record/1)
    # |> Enum.map(&Repo.insert(Application.get_env(:dynamo_migrate, :new_plate_number_table), &1))
    #
    # Logger.info("Plate number table import completed!")
    #
    # Logger.info("Start fiscal code table import")
    #
    # @old_fiscal_code_table
    # |> Dynamo.scan()
    # |> ExAws.request!()
    # |> Repo.parse_result(OldFiscalCode)
    # |> Enum.map(&Repo.convert_record/1)
    # |> Enum.map(&Repo.insert(Application.get_env(:dynamo_migrate, :new_fiscal_code_table), &1))
    #
    # Logger.info("Fiscal code table import completed!")
  end

  defp scan(table_name, last_key, pid) do
    resp =
      Dynamo.scan(table_name, limit: 1, exclusive_start_key: last_key)
      |> IO.inspect()
      |> ExAws.request!()

    Map.get(resp, "Items", [])
    |> Enum.map(&GenServer.call(pid, {:import, &1}))

    scan_continue(resp, table_name, pid)
  end

  defp scan(table_name, pid) do
    resp =
      Dynamo.scan(table_name, limit: 1)
      |> IO.inspect()
      |> ExAws.request!()

    Map.get(resp, "Items", [])
    |> Enum.map(&GenServer.call(pid, {:import, &1}))

    scan_continue(resp, table_name, pid)
  end

  defp scan_continue(term = %{"LastEvaluatedKey" => %{"id" => _}}, table_name, pid) do
    scan(table_name, Map.get(term, "LastEvaluatedKey", %{}), pid)
  end

  defp scan_continue(%{"LastEvaluatedKey" => %{}}, _table_name, _pid) do
    :ok
  end

  defp scan_continue(_, _table_name, _pid) do
    Logger.error("Some error occurred")
    :error
  end
end

defmodule DynamoMigrate.Writer do
  use GenServer

  require Logger
  alias DynamoMigrate.Repo.OldPlateNumber
  alias DynamoMigrate.Repo.OldFiscalCode
  alias DynamoMigrate.Repo

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_call({:import, record}, _from, state) do
    {:reply, do_call(record), state}
  end

  # @impl true
  # def handle_call(_) do
  #   Logger.warn("Unrecognized call message!")
  #   {:reply, :error}
  # end

  defp do_call(record = %{"fiscal_code" => _}) do
    record
    |> Repo.parse(OldFiscalCode)
    |> Repo.convert_record()
    |> Repo.insert(Application.get_env(:dynamo_migrate, :new_fiscal_code_table))
  end

  defp do_call(record = %{"plate_number" => _}) do
    record
    |> Repo.parse(OldPlateNumber)
    |> Repo.convert_record()
    |> Repo.insert(Application.get_env(:dynamo_migrate, :new_plate_number_table))
  end
end

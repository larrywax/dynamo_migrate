defmodule DynamoMigrate.Repo do
  @moduledoc false

  require Logger

  alias ExAws.Dynamo
  alias DynamoMigrate.Repo.OldPlateNumber
  alias DynamoMigrate.Repo.NewPlateNumber
  # alias DynamoMigrate.Repo.OldOldFiscalCode

  @old_plate_number_table Application.get_env(:dynamo_migrate, :dynamo_db)[
                            :old_plate_number_table
                          ]
  # @old_fiscal_code_table Application.get_env(:dynamo_migrate, :dynamo_db)[:old_fiscal_code_table]
  @new_plate_number_table Application.get_env(:dynamo_migrate, :dynamo_db)[
                            :new_plate_number_table
                          ]
  # @new_fiscal_code_table Application.get_env(:dynamo_migrate, :dynamo_db)[:new_fiscal_code_table]

  defp content_to_string(content) do
    content
    |> Enum.sort()
    |> Enum.map(fn {k, v} -> "#{k}#{inspect(v)}" end)
    |> Enum.join()
  end

  defp gen_hash(%{plate_number: pn, record_type: rt, content: content}) do
    c =
      content
      |> decompress
      |> content_to_string

    :crypto.hash(:sha256, "#{pn}#{rt}#{c}")
  end

  def convert_record(
         record = %OldPlateNumber{
           id: id,
           plate_number: plate_number,
           record_type: record_type,
           content: content,
           timestamp_ttl: timestamp
         }
       ) do
    record
    |> Map.from_struct()
    |> Map.drop([:id])
    |> Map.merge((gen_hash(&1)))
  end

  def insert(%{
        hash: hash,
        plate_number: plate_number,
        record_type: record_type,
        content: content,
        timestamp_ttl: timestamp
      }) do
    @new_plate_number_table
    |> Dynamo.put_item(%NewPlateNumber{
      hash: hash,
      plate_number: plate_number,
      record_type: record_type,
      content: content,
      timestamp_ttl: timestamp
    })
    |> retry(&ExAws.request(&1), 5)

    :ok
  end

  # @spec insert(%{fiscal_code: String.t(), record_type: String.t(), content: map()}) :: :ok
  # def insert(%{fiscal_code: fiscal_code, record_type: record_type, content: content}) do
  #   @fiscal_code_table
  #   |> Dynamo.put_item(%OldFiscalCode{
  #     id: UUID.uuid4(),
  #     fiscal_code: fiscal_code,
  #     record_type: record_type,
  #     content: compress(content),
  #     timestamp_ttl: seconds_in_seven_days()
  #   })
  #   |> retry(&ExAws.request(&1), 5)
  #
  #   :ok
  # end
  #
  # @spec get_fiscal_code(String.t()) :: [OldFiscalCode.t()]
  # def get_fiscal_code(fiscal_code) do
  #   @fiscal_code_table
  #   |> Dynamo.query(
  #     limit: 100,
  #     expression_attribute_values: [fiscal_code: fiscal_code],
  #     key_condition_expression: "fiscal_code = :fiscal_code"
  #   )
  #   |> retry(&ExAws.request(&1), 5)
  #   |> parse_result(OldFiscalCode)
  # end
  #
  # @spec get_plate_number(String.t()) :: [OldPlateNumber.t()]
  # def get_plate_number(plate_number) do
  #   @plate_number_table
  #   |> Dynamo.query(
  #     limit: 100,
  #     expression_attribute_values: [plate_number: plate_number],
  #     key_condition_expression: "plate_number = :plate_number"
  #   )
  #   |> retry(&ExAws.request(&1), 5)
  #   |> parse_result(OldPlateNumber)
  # end
  #
  @spec parse_result({:ok, term} | {:error, term}, any()) ::
          [OldPlateNumber.t()] | [OldFiscalCode.t()]
  def parse_result({:error, error}, _module) do
    Logger.error("Errore chiamata DynamoDB all'ultimo tentativo. Reason: #{inspect(error)}",
      error: inspect(error)
    )

    []
  end

  def parse_result(item, module) do
    item
    |> Map.get("Items", [])
    |> Enum.map(&Dynamo.decode_item(&1, as: module))
  end
  #
  @spec retry(
          ExAws.Operation.JSON.t(),
          (any() -> {:error, String.t()} | {:ok, any()}),
          integer()
        ) :: {:ok, term} | {:error, term}
  defp retry(arg, fun, 1) do
    fun.(arg)
  end

  defp retry(arg, fun, n) do
    case fun.(arg) do
      {:error, reason} ->
        Logger.error(
          "Errore chiamata DynamoDB al tentativo #{n}. Ci riprovo. Reason: #{inspect(reason)}",
          error: inspect(reason)
        )

        Process.sleep(500)
        retry(arg, fun, n - 1)

      val ->
        val
    end
  end

  #
  # @spec seconds_in_seven_days :: integer()
  # defp seconds_in_seven_days do
  #   System.system_time(:second) + 604_800
  # end

  defp compress(content) do
    content
    |> Jason.encode!()
    |> :zlib.zip()
  end

  defp decompress(content) do
    content
    |> :zlib.unzip()
    |> Jason.decode!(keys: :atoms)
  end
end

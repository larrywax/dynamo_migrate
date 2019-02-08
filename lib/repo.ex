defmodule DynamoMigrate.Repo do
  @moduledoc false

  require Logger

  alias ExAws.Dynamo
  alias DynamoMigrate.Repo.OldPlateNumber
  alias DynamoMigrate.Repo.NewPlateNumber
  # alias DynamoMigrate.Repo.OldOldFiscalCode

  defp content_to_string(content) do
    content
    |> Enum.sort()
    |> Enum.map(fn {k, v} -> "#{k}#{inspect(v)}" end)
    |> Enum.join()
  end

  defp add_hash(record = %{plate_number: pn, record_type: rt, content: content}) do
    c =
      content
      |> decompress()
      |> content_to_string()

    h = :crypto.hash(:sha256, "#{pn}#{rt}#{c}")

    Map.put(record, :hash, h)
  end

  def convert_record(
        record = %OldPlateNumber{
          id: _id,
          plate_number: _plate_number,
          record_type: _record_type,
          content: _content,
          timestamp_ttl: _timestamp
        }
      ) do
    record
    |> Map.from_struct()
    |> Map.drop([:id])
    |> add_hash()
  end

  # def convert_record(
  #       record = %OldFiscalCode{
  #         id: _id,
  #         fiscal_code: _fiscal_code,
  #         record_type: _record_type,
  #         content: _content,
  #         timestamp_ttl: _timestamp
  #       }
  #     ) do
  #   record
  #   |> Map.from_struct()
  #   |> Map.drop([:id])
  #   |> add_hash()
  # end

  def insert(table, %{
        hash: hash,
        plate_number: plate_number,
        record_type: record_type,
        content: content,
        timestamp_ttl: timestamp
      }) do
    Dynamo.put_item(
      table,
      %NewPlateNumber{
        hash: hash,
        plate_number: plate_number,
        record_type: record_type,
        content: content,
        timestamp_ttl: timestamp
      }
    )
    |> do_insert()
  end

  # def insert(table, %{
  #       hash: hash,
  #       fiscal_code: fiscal_code,
  #       record_type: record_type,
  #       content: content,
  #       timestamp_ttl: timestamp
  #     }) do
  #   Dynamo.put_item(
  #     table,
  #     %NewFiscalCode{
  #       hash: hash,
  #       fiscal_code: fiscal_code,
  #       record_type: record_type,
  #       content: content,
  #       timestamp_ttl: timestamp
  #     }
  #   )
  #   |> do_insert()
  # end

  defp do_insert(payload) do
    case ExAws.request(payload) do
      {:ok, term} ->
        Logger.info("Record inserted succesfully")
        :ok

      {:error, term} ->
        Logger.error("Error in insert: #{inspect(term)}")
    end
  end

  def parse_result(item, module) do
    item
    |> Map.get("Items", [])
    |> Enum.map(&Dynamo.decode_item(&1, as: module))
  end

  defp decompress(content) do
    content
    |> :zlib.unzip()
    |> Jason.decode!(keys: :atoms)
  end
end

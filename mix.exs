defmodule DynamoMigrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :dynamo_migrate,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_dynamo,
       git: "https://github.com/primait/ex_aws_dynamo.git",
       branch: "properly-handle-binary-fields"},
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.1"},
      {:configparser_ex, "~> 2.0"}
    ]
  end
end

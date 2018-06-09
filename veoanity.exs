defmodule H do
  def hex_to_bin(hex_str) do
    Regex.scan(~r(..),hex_str)
    |> Enum.map(fn [x] -> String.to_integer(x, 16) end)
    |> :binary.list_to_bin
  end

  def bin_to_hex(binary) do
    binary
    |> :binary.bin_to_list
    |> Enum.map(fn x -> to_hex(x) end)
    |> Enum.join
  end

  def generate_private_key do
    (for _ <- 1..32, do: :rand.uniform(255))
    |> :binary.list_to_bin
  end

  defp to_hex(i) when i < 16 do
    "0#{Integer.to_string(i, 16)}"
  end

  defp to_hex(i), do: Integer.to_string(i, 16)

  def public_key(private_key) do
    {pub, _} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)
    Base.encode64(pub)
  end

  def print_key_details(private_key) do
    IO.puts "private key    #{H.bin_to_hex(private_key)}"
    IO.puts "public key     #{H.public_key(private_key)}"
  end

  def seconds_to_time_string(s) when s < 100, do: "#{s} sec"
  def seconds_to_time_string(s) when s < 60*60, do: "#{s/60} min"
  def seconds_to_time_string(s) when s < 24*60*60, do: "#{s/3600} hrs"
  def seconds_to_time_string(s), do: "#{s/24/3600} days"

  def loop do
    receive do
      {:key, k} ->
        print_key_details(k)
        IO.puts ""
      _ ->
        nil
    end
    loop()
  end
end



:rand.seed :exs1024s

IO.puts "Here are some fresh random keys and their public keys:"
IO.puts "(For the Amoveo blockchain)"
IO.puts ""

for _ <- 1..5 do
  private = H.generate_private_key
  H.print_key_details(private)
  IO.puts ""
end



#IO.puts "TEST"
#H.print_key_details(H.hex_to_bin("ae2e9fb77a658886dc1b79ffedb390f140cc1ecd6ee88d6ec9efee4aa7b81028"))
#IO.puts ""
# Should print: BK6mimaYA0hDclD1be/wTI9Y9hkfcAYjyjyliFh+TTTSVipJs07vl/g6uCI71f3kFruPu3SxVMtyXYbJTfkvGpM=

IO.puts "(Press Ctrl+C twice to quit)"
IO.puts  ""
pattern =
  IO.gets("To generate a vanity public key, enter a few chars to match: ")
  |> String.trim

if !String.match?(pattern, ~r(^[A-Za-z0-9+/]+$)) do
  IO.puts "The pattern must be base64 alphabet: A-Za-z0-9+/"
  System.halt(1)
end


insensitive =
  IO.gets("Would you like to do a case insensitive search? [y]/n?")
  |> String.match?(~r(^[yY]$))

regex =
  if insensitive do
    Regex.compile!("^..#{pattern}", "i")
  else
    Regex.compile!("^..#{pattern}")
  end

permutations = if insensitive do
    :math.pow((64 - 24), String.length(pattern))
  else
    :math.pow(64, String.length(pattern))
  end


# estimate discovery speed for 1000 keys
t0 = Time.utc_now
Stream.iterate(H.generate_private_key, fn _ -> H.generate_private_key end)
|> Enum.take(1000)
|> Stream.filter(fn priv -> Regex.match?(regex, H.public_key(priv)) end)
|> Stream.run
t1 = Time.utc_now
avg_seconds = Time.diff(t1, t0, :milliseconds) / 1_000_000.0 * permutations / 2.0

IO.puts "Expect this to take on average #{H.seconds_to_time_string avg_seconds} (on one core)"
IO.puts ""

main_process = self()

for _ <- 1..10 do
  Task.async(fn ->
      Stream.iterate(H.generate_private_key, fn _ -> H.generate_private_key end)
      |> Stream.filter(fn priv -> Regex.match?(regex, H.public_key(priv)) end)
      |> Stream.each(fn x -> send(main_process, {:key, x}) end)
      |> Stream.run
    end)
end

# never end the task by itself
H.loop()

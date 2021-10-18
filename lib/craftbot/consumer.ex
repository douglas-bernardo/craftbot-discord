defmodule Craftbot.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do

      msg.content == "!chucknorris" ->
        Api.create_message(
          msg.channel_id,
          "I did not understand you. Try type '!chucknorris help'"
        )

      msg.content == "!covidcasos" ->
        Api.create_message(
          msg.channel_id,
          "Cidade não encontrada. Digite: >> !covidcasos nomedacidade <<"
        )

      msg.content == "!viacep" ->
        Api.create_message(
          msg.channel_id,
          "CEP não encontrado ou comando inválido. Digite: >> !viacep numeroCEP << sem espaço e sem hífen"
        )

      # chucknorris.io https://api.chucknorris.io/
      String.starts_with?(msg.content, "!chucknorris ") ->
        chuck_norris_facts(msg)

      # https://github.com/M-Media-Group/Covid-19-API/?ref=devresourc.es
      String.starts_with?(msg.content, "!covidcasos ") ->
        covidcasos(msg)

      String.starts_with?(msg.content, "!viacep ") ->
        viacep(msg)

      # https://viacep.com.br/?ref=devresourc.es

      true ->
        :ok
    end
  end

  def handle_event(_) do
    :ok
  end

  defp chuck_norris_facts(msg) do
    term =
      msg.content
      |> String.split(" ", parts: 2)
      |> Enum.fetch!(1)

    cond do
      term == "tell me a fact" ->
        resp = HTTPoison.get!("https://api.chucknorris.io/jokes/random")

        case resp.status_code do
          200 ->
            json = Poison.decode!(resp.body)
            fact = json["value"]
            Api.create_message(msg.channel_id, fact)

          404 ->
            Api.create_message(msg.channel_id, "Sorry I don't know what a speak")
        end

      term == "categories" ->
        Api.create_message(
          msg.channel_id,
          "Categories list: animal, career, celebrity, dev, explicit, fashion, food, history, money, movie, music, political, religion, science, sport, travel."
        )

      term == "tell me about" ->
        Api.create_message(
          msg.channel_id,
          "Type any subject from list: animal, career, celebrity, dev, explicit, fashion, food, history, money, movie, music, political, religion, science, sport, travel."
        )

      String.contains?(term, "tell me about ") == true ->
        subject =
          term
          |> String.split()
          |> Enum.fetch!(3)

        resp = HTTPoison.get!("https://api.chucknorris.io/jokes/random?category=#{subject}")

        case resp.status_code do
          200 ->
            json = Poison.decode!(resp.body)
            fact = json["value"]
            Api.create_message(msg.channel_id, fact)

          404 ->
            Api.create_message(msg.channel_id, "Sorry I don't know what a speak")
        end

      term == "help" ->
        Api.create_message(
          msg.channel_id,
          "You can find out a fact about Mr Norris by typing: '!chucknorris tell me a fact' or you might want to know something about a certain subject. For this type '!chucknorris tell me about fashion'"
        )

      true ->
        Api.create_message(
          msg.channel_id,
          "I did not understand you. You are drunk? Try type: '!chucknorris help'"
        )
    end
  end

  defp covidcasos(msg) do
    state =
      msg.content
      |> String.split(" ", parts: 2)
      |> Enum.fetch!(1)

    resp = HTTPoison.get!("https://covid-api.mmediagroup.fr/v1/cases?country=Brazil")
    json = Poison.decode!(resp.body)

    if json[state] do
      confirmed = json[state]["confirmed"]
      recovered = json[state]["recovered"]
      deaths = json[state]["deaths"]
      updated = json[state]["updated"]

      Api.create_message(
        msg.channel_id,
        "Dados de #{state}:\nCasos confirmados: #{confirmed}\nRecuperados: #{recovered}\n Mortes: #{deaths}\n Atualizado em: #{updated}"
      )
    else
      Api.create_message(
        msg.channel_id,
        "Estado não encontrada. Digite o nome de um estado brasileiro sem acentos. Ex. Sao Paulo."
      )
    end
  end

  defp viacep(msg) do
    cep =
      msg.content
      |> String.split(" ", parts: 2)
      |> Enum.fetch!(1)

    response = HTTPoison.get!("https://viacep.com.br/ws/#{cep}/json")

    case response.status_code do
      200 ->
        json = Poison.decode!(response.body)
        logradouro = json["logradouro"]
        bairro = json["bairro"]
        localidade = json["localidade"]
        uf = json["uf"]

        Api.create_message(msg.channel_id, "Logradouro #{logradouro}\nBairro #{logradouro}\nLocalidade #{localidade}\nEstado #{uf}\n")

      404 ->
        Api.create_message(msg.channel_id, "CEP não encontrado")
    end
  end
end

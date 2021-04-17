FROM elixir:1.12

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix local.hex --force && apt-get update && apt-get install -y postgresql-client && mix do compile

CMD ["/app/entrypoint.sh"]
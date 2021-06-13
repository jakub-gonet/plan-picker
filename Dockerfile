FROM elixir:1.11.4-alpine AS asset-builder-mix-getter

ENV HOME=/opt/app
WORKDIR $HOME

RUN mix do local.hex --force, local.rebar --force

COPY config/ ./config/
COPY mix.exs mix.lock ./

RUN mix deps.get

############################################################
FROM node:12.0 as asset-builder

ENV HOME=/opt/app
WORKDIR $HOME

COPY --from=asset-builder-mix-getter $HOME/deps $HOME/deps

WORKDIR $HOME/assets
COPY assets/ ./
RUN npm install
RUN ./node_modules/webpack/bin/webpack.js --mode="production"

############################################################
FROM elixir:1.11.4-alpine

ENV HOME=/opt/app
ENV SECRET_KEY_BASE=yDqPBrnjgmD2M3ByI9rHmkrP169y0w2rHfMIR0Qv5M/uy4SL78isYAYyyYv2RJ9r
ENV PGUSER=postgres
ENV PGPASSWORD=postgres
ENV PGDATABASE=plan_picker_prod
ENV PGPORT=5432
ENV PGHOST=db

WORKDIR $HOME

RUN mix do local.hex --force, local.rebar --force

COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

COPY lib/ ./lib

COPY priv/ ./priv

ENV MIX_ENV=prod
RUN apk add --no-cache build-base postgresql-client

RUN mix do deps.get --only $MIX_ENV, deps.compile, compile

COPY --from=asset-builder $HOME/priv/static/ $HOME/priv/static/
COPY entrypoint.sh entrypoint.sh
RUN mix phx.digest

CMD ["sh", "entrypoint.sh"]
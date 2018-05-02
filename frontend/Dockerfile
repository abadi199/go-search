FROM codesimple/elm:0.18 as build
WORKDIR /frontend
COPY . .
RUN elm make --yes Main.elm --output index.html

FROM nginx
COPY --from=build /frontend/index.html /usr/share/nginx/html

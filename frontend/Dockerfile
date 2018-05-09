FROM codesimple/elm:0.18 as build
WORKDIR /frontend
COPY . .
RUN elm make --yes Main.elm --output dist/elm.js

FROM nginx
COPY --from=build /frontend/dist/* /usr/share/nginx/html/

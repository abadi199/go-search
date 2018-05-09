module Main exposing (..)

import Date exposing (Date)
import DateFormat
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD exposing (Decoder)
import WebSocket


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { keyword : String
    , result : RemoteData (List Person) String
    }


type RemoteData a e
    = NotAsked
    | Loading
    | Reloading a
    | ErrorWithData a e
    | Error e
    | Succeed a


type alias Person =
    { id : String
    , name : String
    , point : Int
    , signup : Date
    }


personDecoder : Decoder Person
personDecoder =
    JD.map4 Person
        (JD.field "_id" JD.string)
        (JD.field "name" JD.string)
        (JD.field "point" JD.int)
        (JD.field "signup"
            (JD.string
                |> JD.andThen
                    (\str ->
                        case Date.fromString str of
                            Err err ->
                                JD.fail err

                            Ok date ->
                                JD.succeed date
                    )
            )
        )


init : ( Model, Cmd Msg )
init =
    ( { keyword = "", result = NotAsked }, Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | keyword = newInput }, Cmd.none )

        Send ->
            ( { model | result = loading model.result }, WebSocket.send "ws://localhost:8081" model.keyword )

        NewMessage str ->
            ( str
                |> JD.decodeString (JD.oneOf [ JD.list personDecoder, JD.null [] ])
                |> Result.map (\people -> { model | result = Succeed people })
                |> Result.mapError (\err -> { model | result = Error err })
                |> resultJoin
            , Cmd.none
            )


loading : RemoteData a e -> RemoteData a e
loading remoteData =
    case remoteData of
        Error _ ->
            Loading

        ErrorWithData a e ->
            Reloading a

        Loading ->
            Loading

        Reloading a ->
            Reloading a

        NotAsked ->
            Loading

        Succeed a ->
            Reloading a


resultJoin : Result a a -> a
resultJoin result =
    case result of
        Ok a ->
            a

        Err a ->
            a



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8081" NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ class "form-inline" ]
            [ div [ class "form-group" ]
                [ input
                    [ onInput Input
                    , onEnter Send
                    , value model.keyword
                    , class "form-control"
                    ]
                    []
                , button [ onClick Send, class "btn btn-primary" ] [ text "Search" ]
                ]
            ]
        , resultView model.result
        ]


onEnter : msg -> Attribute msg
onEnter msg =
    on "keypress"
        (Html.Events.keyCode
            |> JD.andThen
                (\keyCode ->
                    if keyCode == 13 then
                        JD.succeed msg
                    else
                        JD.fail "no care"
                )
        )


resultView : RemoteData (List Person) String -> Html msg
resultView remoteData =
    div []
        (case remoteData of
            NotAsked ->
                [ text "" ]

            Loading ->
                [ loadingView ]

            Reloading a ->
                [ div [] [ text "Loading.." ]
                , peopleView a
                ]

            ErrorWithData a e ->
                [ peopleView a
                , errorView e
                ]

            Error e ->
                [ errorView e ]

            Succeed a ->
                [ peopleView a ]
        )


loadingView : Html msg
loadingView =
    div [] [ text "Loading..." ]


errorView : String -> Html msg
errorView error =
    div [ class "alert alert-danger" ] [ text error ]


peopleView : List Person -> Html msg
peopleView people =
    div []
        [ h2 [] [ text "Result" ]
        , div [] [ text <| "Found " ++ toString (List.length people) ++ " people" ]
        , table [ class "table" ] (List.map personView people)
        ]


personView : Person -> Html msg
personView person =
    tr []
        [ td [] [ text person.id ]
        , td [] [ text person.name ]
        , td [] [ text <| toString person.point ++ " point" ]
        , td []
            [ text <|
                DateFormat.format
                    [ DateFormat.monthNameFull
                    , DateFormat.text " "
                    , DateFormat.dayOfMonthSuffix
                    , DateFormat.text ", "
                    , DateFormat.yearNumber
                    ]
                    person.signup
            ]
        ]

port module Todo exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as Encode
import Json.Decode as Decode exposing (..)
import Debug exposing (log)
import Dom.Scroll
import Task


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
    { entries : List String
    , field : String
    , uid : Int
    , visibility : String
    , socket : Phoenix.Socket.Socket Msg
    }



-- UPDATE


type Msg
    = NoOp
    | SocketMsg (Phoenix.Socket.Msg Msg)
    | RequestEntries
    | ReceiveEntries Encode.Value


responseDecoder : Decode.Decoder String
responseDecoder =
    field "response" Decode.string


init : ( Model, Cmd Msg )
init =
    let
        channelName =
            "subtitle:lobby"

        channel =
            Phoenix.Channel.init channelName
                |> Phoenix.Channel.onJoin (always RequestEntries)

        socketInit =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.on "content" channelName ReceiveEntries

        ( socket, cmd ) =
            Phoenix.Socket.join channel socketInit
    in
        { entries = []
        , visibility = "All"
        , field = ""
        , uid = 0
        , socket = socket
        }
            ! [ Cmd.map SocketMsg cmd ]



-- How we update our Model on a given Msg?


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        SocketMsg msg ->
            let
                ( socket, cmd ) =
                    Phoenix.Socket.update msg model.socket
            in
                { model | socket = socket } ! [ Cmd.map SocketMsg cmd ]

        RequestEntries ->
            let
                push =
                    Phoenix.Push.init "ping" "todo:list"
                        |> Phoenix.Push.onOk ReceiveEntries

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                { model | socket = socket } ! [ Cmd.map SocketMsg cmd ]

        ReceiveEntries raw ->
            let
                entries =
                    log "Ping" raw
            in
                case Decode.decodeValue responseDecoder raw of
                    Ok sentence ->
                        ( { model | entries = model.entries ++ [ sentence ] }
                        , Task.attempt (always NoOp) <| Dom.Scroll.toBottom "sentences"
                        )

                    Err error ->
                        let
                            err =
                                log "Error" error
                        in
                            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ id "sentences" ]
        [ ul [] (List.map viewEntry model.entries) ]


viewEntry : String -> Html Msg
viewEntry entry =
    li [] [ text entry ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.socket SocketMsg

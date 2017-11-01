module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Ports exposing (parseText, progress, receiveText)
import Receipt


-- MODEL


type alias Model =
    { progress : Maybe Progress
    , text : Maybe TextResult
    , products : List Receipt.Product
    }


type alias Progress =
    { status : String
    , progress : Float
    }


type alias TextResult =
    { text : String
    , lines : List String
    }


init : ( Model, Cmd Msg )
init =
    ( { progress = Nothing
      , text = Nothing
      , products = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | UploadFile
    | UpdateProgress Decode.Value
    | ReceiveText Decode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UploadFile ->
            ( model, parseText fileUploadId )

        UpdateProgress value ->
            let
                progress =
                    value
                        |> Decode.decodeValue progressDecoder
                        |> Result.toMaybe
            in
                ( { model | progress = progress }, Cmd.none )

        ReceiveText value ->
            let
                text =
                    value
                        |> Decode.decodeValue textResultDecoder
                        |> Result.toMaybe

                products =
                    getProducts text
            in
                ( { model | text = text, products = products }, Cmd.none )


getProducts : Maybe TextResult -> List Receipt.Product
getProducts text =
    case text of
        Nothing ->
            []

        Just { lines } ->
            lines
                |> List.map Receipt.parseProduct
                |> List.filterMap identity



-- VIEW


fileUploadId : String
fileUploadId = "file-upload"


view : Model -> Html Msg
view model =
    Html.div
        [ Attributes.class "container" ]
        [ Html.input
            [ Attributes.type_ "file"
            , Attributes.id fileUploadId
            , Events.on "change" (Decode.succeed UploadFile)
            ]
            []
        , Html.div
            [ Attributes.class "file-upload-text" ]
            [ Html.text "Add a Receipt" ]
        , Html.label
            [ Attributes.for fileUploadId ]
            [ Html.i
                [ Attributes.class "material-icons" ]
                [ Html.text "file_upload" ]
            ]
        , progressBar model.progress
        , resultBox model.products
        ]


progressBar : Maybe Progress -> Html msg
progressBar maybeProgress =
    case maybeProgress of
        Nothing ->
            Html.text ""

        Just { status, progress } ->
            Html.div
                [ Attributes.class "progress-info" ]
                [ Html.div
                    [ Attributes.class "status-indicator" ]
                    [ Html.text status ]
                , Html.div
                    [ Attributes.class "progress-bar" ]
                    [ Html.div
                        [ Attributes.class "progress"
                        , Attributes.style [ ( "width", progressWidth progress ) ]
                        ]
                        []
                    ]
                ]


resultBox : List Receipt.Product -> Html msg
resultBox products =
    Html.div
        [ Attributes.class "result-box" ]
        (List.map resultLine products)


resultLine : Receipt.Product -> Html msg
resultLine { name, price } =
    Html.p [] [ Html.text (name ++ ": $" ++ (toString price)) ]


progressWidth : Float -> String
progressWidth progress =
    progress * 100
        |> toString
        |> (flip (++)) "%"


-- SUBSCRIPTIONS


progressDecoder : Decode.Decoder Progress
progressDecoder =
    Pipeline.decode Progress
        |> Pipeline.required "status" Decode.string
        |> Pipeline.required "progress" Decode.float


textResultDecoder : Decode.Decoder TextResult
textResultDecoder =
    Pipeline.decode TextResult
        |> Pipeline.required "text" Decode.string
        |> Pipeline.required "lines" (Decode.list lineDecoder)


lineDecoder : Decode.Decoder String
lineDecoder =
    Decode.at ["text"] Decode.string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ progress UpdateProgress
        , receiveText ReceiveText
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }

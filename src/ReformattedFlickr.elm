module ReformattedFlickr where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (Task, andThen)
import Window


-- VIEW


view : Int -> String -> String -> Html
view height string imgUrl =
    Html.div
        [ Attr.style (imgStyle height imgUrl) ]
        [
            Html.input
                [
                    Attr.placeholder "Flickr Query",
                    Attr.value string,
                    Attr.style queryInputStyle,
                    Event.on "input" Event.targetValue (Signal.message query.address)
                ]
                []
        ]


queryInputStyle : List (String, String)
queryInputStyle =
    [
        ("width",      "100%"),
        ("height",     "40px"),
        ("padding",    "10px 0"),
        ("font-size",  "2em"),
        ("text-align", "center")
    ]


imgStyle : Int -> String -> List (String, String)
imgStyle height src =
    [
        ("background-image",      "url('" ++ src ++ "')"),
        ("background-repeat",     "no-repeat"),
        ("background-attachment", "fixed"),
        ("background-position",   "center"),
        ("width",                 "100%"),
        ("height",                (toString height) ++ "px")
    ]


-- WIRING

main : Signal Html
main =
    Signal.map3 view Window.height query.signal results.signal


results : Signal.Mailbox String
results =
    Signal.mailbox "waiting.gif"


port requestImgs : Signal (Task Http.Error ())
port requestImgs =
    query.signal
        |> sample getImage Window.dimensions
        |> Signal.map (\task -> task `andThen` Signal.send results.address)


sample func sampled events =
    Signal.sampleOn events (Signal.map2 func sampled events)


query : Signal.Mailbox String
query =
    Signal.mailbox ""


getImage : (Int,Int) -> String -> Task Http.Error String
getImage dimensions tag =
    let
        searchArgs =
            [ ("sort", "random"), ("per_page", "10"), ("tags", tag) ]
    in
        Http.get
            photoList (flickr "search" searchArgs)
        `andThen`
            selectPhoto
        `andThen` \photo ->
            Http.get sizeList (flickr "getSizes" [ ("photo_id", photo.id) ])
        `andThen`
            pickSize dimensions


-- JSON DECODERS

type alias Photo =
    {
        id    : String,
        title : String
    }


type alias Size =
    {
        source : String,
        width  : Int,
        height : Int
    }


photoList : Json.Decoder (List Photo)
photoList =
    Json.at ["photos","photo"] <|
        Json.list <|
            Json.object2
                Photo
                ("id"    := Json.string)
                ("title" := Json.string)


sizeList : Json.Decoder (List Size)
sizeList =
    Json.at ["sizes","size"] <|
        Json.list <|
            Json.object3
                Size
                ("source" := Json.string)
                ("width"  := intOrStringInt)
                ("height" := intOrStringInt)


-- the value might be either 42 or "42"
intOrStringInt =
    Json.oneOf
        [
            Json.int,
            Json.customDecoder Json.string String.toInt
        ]


--  FLICKR URLS

flickr : String -> List (String, String) -> String
flickr method args =
    Http.url "https://api.flickr.com/services/rest/" <|
        [
            ("format",         "json"),
            ("nojsoncallback", "1"),
            ("api_key",        "9be5b08cd8168fa82d136aa55f1fdb3c"),
            ("method",         "flickr.photos." ++ method)
        ] ++ args


-- HANDLE RESPONSES

selectPhoto : List Photo -> Task Http.Error Photo
selectPhoto photos =
    case photos of
        photo :: _ ->
            Task.succeed photo

        [] ->
            Task.fail (Http.UnexpectedPayload "expecting 1 or more photos from Flickr")


pickSize : (Int,Int) -> List Size -> Task Http.Error String
pickSize (width,height) sizes =
    let
        sizeRating size =
            let
                penalty =
                    if (size.width > width) || (size.height > height) then
                        400
                    else
                        0
            in
                abs (width - size.width) + abs (height - size.height) + penalty
    in
        case List.sortBy sizeRating sizes of
            size :: _ ->
                Task.succeed size.source

            [] ->
                Task.fail (Http.UnexpectedPayload "expecting 1 or more image sizes to choose from")


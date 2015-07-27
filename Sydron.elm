module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (Task, andThen)
import Window


-- VIEW

view : Int -> String -> (List Event) -> Html
view height string someStuff =
    Html.div
        [ ]
        [Html.ul [] (List.map (.eventType >> Html.text >> (\a -> [a]) >> Html.li []) someStuff)]


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
    Signal.map3 view Window.height query.signal newEvents.signal

--- Jess Makes Some Stuff
pleaseFetchPage : Signal.Mailbox Int
pleaseFetchPage = Signal.mailbox 1

-- Question: will the port fire initially? what I want is for this to fire on "go"
port retrievePageOfEvents : Signal (Task Http.Error ())
port retrievePageOfEvents =
  pleaseFetchPage.signal
    |> Signal.map fetchPageOfEvents
    |> Signal.map( \task -> task `andThen` Signal.send newEvents.address)

newEvents : Signal.Mailbox (List Event)
newEvents = Signal.mailbox []

fetchPageOfEvents : Int -> Task Http.Error (List Event)
fetchPageOfEvents pageNo =
    let
      parameters = [("page", toString pageNo)]
    in 
      Http.get githubEvents (github "satellite-of-love" "Hungover" pageNo)

github : String -> String -> Int -> String
github owner repo pageNo = Http.url ("https://api.github.com/repos/" ++ owner ++ "/" ++ repo ++ "/events") <|
        [("pageNo", (toString pageNo))]
-- end Jess

query : Signal.Mailbox String
query =
    Signal.mailbox ""

-- JSON DECODERS

type alias Event = 
  {
    eventType : String
  }

githubEvents : Json.Decoder (List Event)
githubEvents =
    Json.list <| 
        Json.object1
          Event
          ("type" := Json.string)




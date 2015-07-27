module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (Task, andThen)
import Window
import Time


-- VIEW

singleItemList : a -> List a
singleItemList item = [item]

eventListItem : Event -> Html
eventListItem event =
    Html.li [] [Html.text (event.eventType ++ " by " ++ event.actor.login)]

view : Int -> String -> (List Event) -> Html
view height string someStuff =
    Html.div
        [ ]
        [Html.ul [] (List.map eventListItem someStuff)]


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
    Signal.map3 view Window.height query.signal seenEvents

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

everyFewSeconds : Signal EventsOrTimer
everyFewSeconds = Signal.map (\_ -> Heartbeat) (Time.every 3000)

eventsAndTimer : Signal EventsOrTimer
eventsAndTimer = Signal.merge everyFewSeconds (Signal.map (\e -> SomeNewEvents (List.reverse e)) newEvents.signal)
moveOneOver : SomeEventModel -> SomeEventModel
moveOneOver events = 
    case events.unseen of 
        [] -> events
        head :: tail -> { seen = head :: events.seen, unseen = tail}

type alias SomeEventModel = { seen: List Event, unseen: List Event}
type EventsOrTimer = Heartbeat | SomeNewEvents (List Event)
updateSomeEvents : EventsOrTimer -> SomeEventModel -> SomeEventModel
updateSomeEvents action before =
  case action of
    Heartbeat -> moveOneOver before
    SomeNewEvents events -> { seen = before.seen, unseen = before.unseen ++ events }


someEvents : Signal SomeEventModel
someEvents = Signal.foldp updateSomeEvents (SomeEventModel [] []) eventsAndTimer 

seenEvents : Signal (List Event)
seenEvents = Signal.map .seen someEvents 

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

type alias EventActor = 
    { 
      login: String,
      avatar_url: String
    }

type alias Event = 
  {
    eventType : String,
    actor : EventActor
  }

githubEventActor : Json.Decoder EventActor
githubEventActor = 
    Json.object2
      EventActor
        ("login" := Json.string)
        ("avatar_url" := Json.string)

githubEvents : Json.Decoder (List Event)
githubEvents =
    Json.list <| 
        Json.object2
          Event
          ("type" := Json.string)
          ("actor" := githubEventActor)




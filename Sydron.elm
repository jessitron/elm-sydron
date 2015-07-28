module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task exposing (Task, andThen)
import Time

-- MODEL

type alias Model = 
    {
      seenEvents   : List Event,
      queuedEvents : List Event
    }


-- VIEW

eventListItem : Event -> Html
eventListItem event =
    Html.li [] [Html.text (event.eventType ++ " by " ++ event.actor.login)]

view : Model -> Html
view someStuff =
    Html.div
        [ ]
        [Html.h2 [] (List.map eventListItem someStuff.seenEvents)]

-- UPDATE

type Action = 
      Heartbeat 
    | SomeNewEvents (List Event)

update: Action -> Model -> Model
update action model =
    case action of
        Heartbeat -> moveOneOver model
        SomeNewEvents events -> queueEvents model events

-- WIRING

type alias App modelt action =
    { model : modelt
    , view : modelt -> Html
    , update : action -> modelt -> modelt
    }
start : App Model Action -> Signal Html
start app =
  let
    model =
      Signal.foldp
        (\a m -> app.update a m)
        app.model
        eventsAndTimer
  in
    Signal.map app.view model

main = start { model = Model [] [], view = view, update = update}

--- Jess Makes Some Stuff
pleaseFetchPage : Signal.Mailbox Int
pleaseFetchPage = Signal.mailbox 1

port retrievePageOfEvents : Signal (Task Http.Error ())
port retrievePageOfEvents =
  pleaseFetchPage.signal
    |> Signal.map fetchPageOfEvents
    |> Signal.map( \task -> task `andThen` Signal.send newEvents.address)

newEvents : Signal.Mailbox (List Event)
newEvents = Signal.mailbox []

everyFewSeconds : Signal Action
everyFewSeconds = Signal.map (\_ -> Heartbeat) (Time.every 3000)

eventsAndTimer : Signal Action
eventsAndTimer = Signal.merge everyFewSeconds (Signal.map (\e -> SomeNewEvents (List.reverse e)) newEvents.signal)

type alias SomeEventModel = 
    { 
      seen: List Event, 
      unseen: List Event
    }
moveOneOver : Model -> Model
moveOneOver model = 
    case model.queuedEvents of 
        [] -> model
        head :: tail -> { seenEvents = head :: model.seenEvents, queuedEvents = tail }
queueEvents : Model -> List Event -> Model
queueEvents model moreEvents =
    { seenEvents = model.seenEvents, queuedEvents = model.queuedEvents ++ moreEvents }
-- todo: record "suchthat" syntax

-- Fetchy Fetchy

fetchPageOfEvents : Int -> Task Http.Error (List Event)
fetchPageOfEvents pageNo =
    let
      parameters = [("page", toString pageNo)]
    in 
      Http.get githubEvents (github "satellite-of-love" "Hungover" pageNo)

github : String -> String -> Int -> String
github owner repo pageNo = Http.url ("https://api.github.com/repos/" ++ owner ++ "/" ++ repo ++ "/events") <|
        [("pageNo", (toString pageNo))]

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




module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import String
import Task exposing (Task, andThen)
import Time
import GithubEvent exposing (Event)

-- MODEL

type alias Model =
  {
     ticker: List Event
  }


-- VIEW

eventListItem : Event -> Html
eventListItem event =
    Html.li [] [Html.text (event.eventType ++ " by " ++ event.actor.login)]

view : Model -> Html
view someStuff =
    Html.div
        [ ]
        [Html.h2 [] (List.map eventListItem someStuff.ticker)]

-- UPDATE

type alias Action = SingleEvent

update: Action -> Model -> Model
update action model =
    case action of
        Boring -> model
        SoThisHappened event -> Model (List.take 3 (event :: model.ticker))

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
        spreadEvents
  in    
    Signal.map app.view model

main = start { model = Model [], view = view, update = update}

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

type InnerStuff = 
  Heartbeat 
  | SomeNewEvents (List Event)

everyFewSeconds : Signal InnerStuff
everyFewSeconds = Signal.map (\_ -> Heartbeat) (Time.every 3000)

eventsAndTimer : Signal InnerStuff
eventsAndTimer = Signal.merge everyFewSeconds (Signal.map (\e -> SomeNewEvents (List.reverse e)) newEvents.signal)


type alias SplitEvents = 
    {
      seenEvents   : List Event,
      queuedEvents : List Event
    }
splitEvents: InnerStuff -> SplitEvents -> SplitEvents
splitEvents action before =
    case action of
        Heartbeat -> moveOneOver before
        SomeNewEvents events -> queueEvents before events

singleEvent: SplitEvents -> SingleEvent
singleEvent splitEvents =
  case splitEvents.seenEvents of
    [] -> Boring
    head :: _ -> SoThisHappened head

type SingleEvent = SoThisHappened Event | Boring
spreadEvents : Signal SingleEvent
spreadEvents = 
  Signal.foldp splitEvents (SplitEvents [] []) eventsAndTimer
  |> Signal.map singleEvent

type alias SomeEventModel = 
    { 
      seen: List Event, 
      unseen: List Event
    }
moveOneOver : SplitEvents -> SplitEvents
moveOneOver before = 
    case before.queuedEvents of 
        [] -> before
        head :: tail -> { seenEvents = head :: before.seenEvents, queuedEvents = tail }
queueEvents : SplitEvents -> List Event -> SplitEvents
queueEvents before moreEvents =
    { seenEvents = before.seenEvents, queuedEvents = before.queuedEvents ++ moreEvents }
-- todo: record "suchthat" syntax

-- Fetchy Fetchy

fetchPageOfEvents : Int -> Task Http.Error (List Event)
fetchPageOfEvents pageNo =
    let
      parameters = [("page", toString pageNo)]
    in 
      Http.get GithubEvent.listDecoder (github "satellite-of-love" "Hungover" pageNo)

github : String -> String -> Int -> String
github owner repo pageNo = Http.url ("https://api.github.com/repos/" ++ owner ++ "/" ++ repo ++ "/events") <|
        [("pageNo", (toString pageNo))]





module GithubEventSignal(SingleEvent(..), eventsOneByOne, fetchOnce) where

import Http
import GithubEvent exposing (Event)
import Time
import Task exposing (Task, andThen)


type SingleEvent = NothingYet | SoThisHappened Event

--- Jess Makes Some Stuff
pleaseFetchPage : Signal.Mailbox Int
pleaseFetchPage = Signal.mailbox 1

fetchOnce: Signal (Task Http.Error ())
fetchOnce = 
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

singleEvents: SplitEvents -> Maybe Event
singleEvents splitEvents =
  case splitEvents.seenEvents of
    [] -> Nothing
    head :: _ -> Just head

eventsOneByOne : Signal SingleEvent
eventsOneByOne = 
  Signal.foldp splitEvents (SplitEvents [] []) eventsAndTimer
  |> Signal.map singleEvents
  |> Signal.filterMap (\a -> Maybe.map SoThisHappened a) NothingYet

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





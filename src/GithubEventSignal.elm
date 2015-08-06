module GithubEventSignal(SingleEvent(..), eventsOneByOne, fetchOnce, GithubRepository, setRepo) where

import Http
import GithubEvent exposing (Event)
import Time
import Task exposing (Task, andThen)


type SingleEvent = NothingYet | SoThisHappened Event

setRepo: GithubRepository -> Task a ()
setRepo r = Signal.send repository.address r

type alias GithubRepository = 
  {
    owner: String,
    repo : String,
    githubUrl : Maybe String
  }

--- port
fetchOnce: GithubRepository -> Signal (Task Http.Error ())
fetchOnce ofWhat = 
  Signal.constant ofWhat
    |> Signal.map fetchPageOfEvents
    |> Signal.map (\task -> task `andThen` Signal.send newEvents.address)

-- wiring

repository: Signal.Mailbox GithubRepository
repository = Signal.mailbox (GithubRepository "satellite-of-love" "Hungover" Nothing)

newEvents : Signal.Mailbox (List Event)
newEvents = Signal.mailbox []

-- signal
eventsOneByOne : Signal SingleEvent
eventsOneByOne =
  newEvents.signal
   |> Signal.map (\e -> SomeNewEvents (List.reverse e))
   |> Signal.merge everyFewSeconds
   |> Signal.foldp splitEvents (SplitEvents [] [])
   |> Signal.map singleEvents
   |> Signal.filterMap (\a -> Maybe.map SoThisHappened a) NothingYet

-- private

type InnerStuff = 
  Heartbeat 
  | SomeNewEvents (List Event)

everyFewSeconds : Signal InnerStuff
everyFewSeconds = Signal.map (\_ -> Heartbeat) (Time.every 3000)

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
  case splitEvents.queuedEvents of
    [] -> Nothing
    head :: _ -> Just head

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


fetchPageOfEvents : GithubRepository -> Task Http.Error (List Event)
fetchPageOfEvents repo =
    let
      pageNo = 1
      parameters = [("page", toString pageNo)]
    in 
      Http.get GithubEvent.listDecoder (github repo pageNo)

realGithubUrl = "https://api.github.com/repos"

github : GithubRepository -> Int -> String
github repo pageNo = Http.url ( (Maybe.withDefault realGithubUrl repo.githubUrl) ++ "/" ++ repo.owner ++ "/" ++ repo.repo ++ "/events") <|
        [("pageNo", (toString pageNo))]





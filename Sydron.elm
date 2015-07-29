module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import String
import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..))
import Task
import Http

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

type alias Action = GithubEventSignal.SingleEvent

update: Action -> Model -> Model
update action model =
    case action of
        NothingYet -> model
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
        GithubEventSignal.eventsOneByOne
  in    
    Signal.map app.view model

main = start { model = Model [], view = view, update = update}

--- WORLD

port githubEventsPort : Signal (Task.Task Http.Error ())
port githubEventsPort = GithubEventSignal.fetchOnce


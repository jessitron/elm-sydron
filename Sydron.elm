module Sydron where

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..))
import Task
import Http
-- for actual use
import EventTicker

-- MODEL

type alias Model =
  {
     ticker: EventTicker.Model
  }
init = Model EventTicker.init


-- VIEW

view : Model -> Html
view m =
    Html.div
        [ ]
        [ EventTicker.view m.ticker ]

-- UPDATE

type alias Action = GithubEventSignal.SingleEvent

update: Action -> Model -> Model
update action model =
     { model | ticker <- EventTicker.update action model.ticker }

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

main = start { model = init, view = view, update = update}

--- WORLD

port githubEventsPort : Signal (Task.Task Http.Error ())
port githubEventsPort = GithubEventSignal.fetchOnce


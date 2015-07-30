module Sydron where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Task
import Http
import Signal exposing (Signal)
import Time exposing (Time)
-- for actual use
import EventTicker
import SeeThePeople

-- MODEL

type alias Model =
  {
     ticker: EventTicker.Model,
     people: SeeThePeople.Model
  }
init = 
  Model 
    EventTicker.init 
    SeeThePeople.init


-- VIEW

view : Model -> Html
view m =
    Html.div
        [ ]
        [ pageTitle,
          EventTicker.view m.ticker ,
          SeeThePeople.view m.people
        ]

-- todo: move this to index.html
pageTitle = 
  Html.div 
    [ Attr.style 
      [ 
        ("height", "100px"),
        ("font-family", "Helvetica"),
        ("margin-top", "20px"), 
        ("margin-left", "20px")
      ]
    ]
  [ 
    Html.h1 [] 
      [Html.text "Sydron"],
    Html.text "A parade of Github Events for ",
    Html.a [Attr.href "http://github.com/satellite-of-love/Hungover" ] [ Html.text "Rachel's baby game repo"],
    Html.text ". This is me playing with Elm; source code ",
    Html.a [Attr.href "http://github.com/jessitron/elm-sydron"] [ Html.text "here" ],
    Html.text "."
  ]

-- UPDATE

update: SydronAction -> Model -> Model
update action model =
  case action of
    SingleEvent e -> 
     { model | ticker <- EventTicker.update e model.ticker,
               people <- SeeThePeople.update e model.people }
    TimeKeepsTickingAway t -> model

-- WIRING

type alias App modelt action =
    { model : modelt
    , view : modelt -> Html
    , update : action -> modelt -> modelt
    }
start : App Model SydronAction -> Signal Html
start app =
  let
    model =
      Signal.foldp
        (\a m -> app.update a m)
        app.model
        both
  in    
    Signal.map app.view model

main = start { model = init, view = view, update = update}

--- WORLD

port githubEventsPort : Signal (Task.Task Http.Error ())
port githubEventsPort = GithubEventSignal.fetchOnce

timePasses : Signal Time
timePasses =  (Signal.map Time.inMilliseconds (Time.fps 30))

both : Signal SydronAction
both = Signal.merge 
  (Signal.map TimeKeepsTickingAway timePasses)
  (Signal.map SingleEvent GithubEventSignal.eventsOneByOne)


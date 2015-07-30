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

type alias Action = GithubEventSignal.SingleEvent

update: Action -> Model -> Model
update action model =
     { model | ticker <- EventTicker.update action model.ticker,
               people <- SeeThePeople.update action model.people }

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


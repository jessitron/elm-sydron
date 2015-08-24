module Sydron where

import SydronAction exposing (SydronAction(..))
import GithubEventLayer
import GithubRepository exposing (GithubRepository)
import Task
import Http
import Signal exposing (Signal)
import Time exposing (Time)
import ParseUrlParams
import SydronInt exposing (init, view, update)
import StartApp
import Effects exposing (Never)
import Dict exposing (Dict)
import String
import Maybe exposing (andThen)


--- WIRING

app = StartApp.start (StartApp.Config
                       (GithubEventLayer.init repositoryOfInterest)
                       GithubEventLayer.update
                       GithubEventLayer.view
                       [animationFrames, showNewEvent])


main = app.html


port tasks : Signal (Task.Task Never ())
port tasks =
    app.tasks


--- WORLD


port initialLocation: String


urlParameters: Dict String String
urlParameters = (ParseUrlParams.parse initialLocation)


repositoryOfInterest =
  GithubRepository.fromDict
     urlParameters
    "satellite-of-love" "Hungover"


animationFrames : Signal GithubEventLayer.Action
animationFrames =
    Time.fps 30
        |> Signal.map (Time.inMilliseconds >> wrapTickAction)


wrapTickAction : Time -> GithubEventLayer.Action
wrapTickAction ms =
    GithubEventLayer.wrapAction (TimeKeepsTickingAway ms)


showNewEvent: Signal GithubEventLayer.Action
showNewEvent =
    urlParameters
        |> ParseUrlParams.integerParam "frequency" 3
        |> toFloat
        |> (*) Time.second
        |> Time.every
        |> Signal.map (always GithubEventLayer.Heartbeat)

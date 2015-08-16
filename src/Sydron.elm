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


--- WIRING
 
app = StartApp.start (StartApp.Config 
                       (GithubEventLayer.init repositoryOfInterest)
                       GithubEventLayer.update
                       GithubEventLayer.view
                       [animationFrames])
main = app.html

port tasks : Signal (Task.Task Never ())
port tasks =
    app.tasks

--- WORLD

port initialLocation: String

repositoryOfInterest = 
  GithubRepository.fromDict 
    (ParseUrlParams.parse initialLocation) 
    "satellite-of-love" "Hungover"

timePasses : Signal Time
timePasses =  (Signal.map Time.inMilliseconds (Time.fps 30))

animationFrames : Signal GithubEventLayer.Action
animationFrames = Signal.map TimeKeepsTickingAway timePasses
                  |> Signal.map GithubEventLayer.wrapAction 


module Sydron where

import SydronAction exposing (SydronAction(..))
import GithubEventSignal exposing (SingleEvent(..))
import GithubRepository exposing (GithubRepository) 
import Task
import Http
import Signal exposing (Signal)
import Time exposing (Time)
import ParseUrlParams
import SydronInt exposing (start)


-- WIRING


main =
  start both repositoryOfInterest

--- WORLD

port initialLocation: String

repositoryOfInterest = 
  GithubRepository.fromDict 
    (ParseUrlParams.parse initialLocation) 
    "satellite-of-love" "Hungover"

port githubEventsPort : Signal (Task.Task Http.Error ())
port githubEventsPort = GithubEventSignal.fetchOnce repositoryOfInterest

timePasses : Signal Time
timePasses =  (Signal.map Time.inMilliseconds (Time.fps 30))

both : Signal SydronAction
both = Signal.merge 
  (Signal.map TimeKeepsTickingAway timePasses)
  (Signal.map SingleEvent GithubEventSignal.eventsOneByOne)


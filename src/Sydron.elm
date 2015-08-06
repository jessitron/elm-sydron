module Sydron where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..), GithubRepository)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Task
import Http
import String
import Dict
import Maybe
import Signal exposing (Signal)
import Time exposing (Time)
import SydronInt exposing (Model, view, update, init)


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

main =
  start { model = (init repositoryOfInterest), view = view, update = update}

--- WORLD

port initialLocation: String

inputParameters : Dict.Dict String String
inputParameters = 
  if (String.isEmpty initialLocation) then
     Dict.empty
  else
    let 
      loseTheQuestionMark = String.dropLeft 1 initialLocation
      args = String.split "&" loseTheQuestionMark
      listsOfTwo = List.map (String.split "=") args
      pairs = List.map makeTheseTwoThingsIntoATuple listsOfTwo
      mappydoober = Dict.fromList pairs
    in 
      mappydoober

parse: Dict.Dict String String -> GithubRepository
parse mappydoober =
  GithubEventSignal.GithubRepository 
        (Maybe.withDefault "satellite-of-love" (Dict.get "owner" mappydoober))
        (Maybe.withDefault "Hungover" (Dict.get "repo-name" mappydoober))
        (Dict.get "github" mappydoober)

makeTheseTwoThingsIntoATuple: List String -> (String,String)
makeTheseTwoThingsIntoATuple inp = 
  case inp of
    head :: (head2 :: []) -> (head, head2)

repositoryOfInterest = parse inputParameters

port githubEventsPort : Signal (Task.Task Http.Error ())
port githubEventsPort = GithubEventSignal.fetchOnce repositoryOfInterest

timePasses : Signal Time
timePasses =  (Signal.map Time.inMilliseconds (Time.fps 30))

both : Signal SydronAction
both = Signal.merge 
  (Signal.map TimeKeepsTickingAway timePasses)
  (Signal.map SingleEvent GithubEventSignal.eventsOneByOne)


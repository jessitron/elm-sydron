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
-- for actual use
import EventTicker
import SeeThePeople
import Header

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
        [ Header.view repositoryOfInterest,
          inputThinger,
          EventTicker.view m.ticker ,
          SeeThePeople.view m.people
        ]

inputThinger : Html
inputThinger = 
  Html.div []
    [ Html.form [ Attr.style [("class", "pure-form")]] [
       Html.input [ Attr.placeholder "owner", Attr.name "owner", Attr.value (inputParameter "owner")] [],
       Html.input [ Attr.placeholder "repository", Attr.name "repo-name", Attr.value (inputParameter "repo-name")] [],
       Html.button [ Attr.style [("background", "url('img/elm-button.jpg')"), ("width", "137px"), ("height", "100px")]] [Html.text "Go"]
    ]]

inputParameter key = (Maybe.withDefault "" (Dict.get key inputParameters))

-- UPDATE

update: SydronAction -> Model -> Model
update action m =
  m 
  |> updatePeople action
  |> updateTicker action

updatePeople : SydronAction -> Model -> Model
updatePeople action model =
  { model | people <- SeeThePeople.update action model.people }
-- is there an "updateIn" for records?

updateTicker : SydronAction -> Model -> Model
updateTicker action model =
  case action of
    SingleEvent e -> 
     { model | ticker <- EventTicker.update e model.ticker }
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

main =
  start { model = init, view = view, update = update}

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


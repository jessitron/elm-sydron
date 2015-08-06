module SydronInt(Model, view, init, update, start) where

import GithubEventSignal exposing (GithubRepository)
import SydronAction exposing (SydronAction(..))
import Html exposing (Html)
-- for actual use
import EventTicker
import SeeThePeople
import Header
import RepoInput

-- MODEL

type alias Model =
  {
     repositoryOfInterest: GithubRepository,
     ticker: EventTicker.Model,
     people: SeeThePeople.Model
  }
init repositoryFromUrlParams = 
  Model 
    repositoryFromUrlParams
    EventTicker.init 
    SeeThePeople.init


-- VIEW

formclass = "pure-form" -- this is dependent on index.html including purecss

view : Model -> Html
view m =
    Html.div
        [ ]
        [ Header.view m.repositoryOfInterest,
          RepoInput.view formclass m.repositoryOfInterest,
          EventTicker.view m.ticker,
          SeeThePeople.view m.people
        ]


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


--- WIRING

type alias App modelt action =
    { model : modelt
    , view : modelt -> Html
    , update : action -> modelt -> modelt
    }
start : Signal SydronAction -> App Model SydronAction -> Signal Html
start signals app =
  let
    model =
      Signal.foldp
        (\a m -> app.update a m)
        app.model
        signals
  in    
    Signal.map app.view model
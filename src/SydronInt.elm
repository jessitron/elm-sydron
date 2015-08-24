module SydronInt(update, init, view, Model) where

import GithubRepository exposing (GithubRepository)
import SydronAction exposing (SydronAction(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Effects exposing (Effects)
-- for actual use
import EventTicker
import SeeThePeople
import Header
import RepoInput

-- MODEL

type alias Model =
  {
     repo: GithubRepository,
     ticker: EventTicker.Model,
     people: SeeThePeople.Model
  }

init: GithubRepository -> Model
init repositoryFromUrlParams =
  Model
    repositoryFromUrlParams
    EventTicker.init
    SeeThePeople.init


-- VIEW


formclass = "pure-form" -- this is dependent on index.html including purecss


view : Signal.Address SydronAction -> Model -> Html
view addr m =
    div
        [ ]
        [ Header.view m.repo,
          RepoInput.view formclass,
          span [] [EventTicker.view addr m.ticker],
          span [] [SeeThePeople.view addr m.people]
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
  { model | ticker <- EventTicker.update action model.ticker }


(=>) = (,)

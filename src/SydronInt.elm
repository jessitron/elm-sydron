module SydronInt(update, init, view, Model) where

import GithubRepository exposing (GithubRepository)
import SydronAction exposing (SydronAction(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Effects exposing (Effects)
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
    Html.div
        [ ]
        [ Header.view m.repositoryOfInterest,
          RepoInput.view formclass,
          Html.div [inline] [EventTicker.view addr m.ticker],
          Html.div [inline] [SeeThePeople.view addr m.people]
        ]

inline: Html.Attribute
inline = Attr.style [("display", "inline")]

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

module EventTicker(Model, init, view, update) where

import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..))
import Html exposing (Html)

-- Model

type alias Model = 
  {
    upToThreeRecentEvents : List Event
  }
init: Model 
init = Model []

-- View
eventListItem : Event -> Html
eventListItem event =
    Html.li [] [Html.text (event.eventType ++ " by " ++ event.actor.login)]

view : Model -> Html
view m =
    Html.div
        [ ]
        [ Html.h2 [] (List.map eventListItem m.upToThreeRecentEvents) ]

-- Update
type alias Action = GithubEventSignal.SingleEvent

update: Action -> Model -> Model
update action model =
    case action of
        NothingYet -> model
        SoThisHappened event -> Model (List.take 3 (event :: model.upToThreeRecentEvents))
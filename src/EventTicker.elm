module EventTicker(Model, init, view, update) where

import GithubEvent exposing (Event)
import GithubEventSignal exposing (SingleEvent(..))
import Html exposing (Html)
import Html.Attributes exposing (style)

-- Model

type alias Model = 
  {
    recentEvents : List Event
  }
init: Model 
init = Model []

-- View
eventListItem : Event -> Html
eventListItem event =
    Html.div [itemStyle]
    [Html.text (event.eventType ++ " by " ++ event.actor.login ++ " at " ++ event.created_at)]

view : Model -> Html
view m =
    Html.div
        [ divStyle ]
        (List.map eventListItem m.recentEvents)

divStyle = 
  style 
    [  
      ("height", "100px"),
      ("box-sizing", "border-box"),
      ("border", "1px solid"),
      ("color", "#666666"),
      ("overflow", "scroll"),
      ("padding", "10px")
    ]
itemStyle = 
  style 
    [ 
      ("color", "#515151"),
      ("font-family", "Helvetica"),
      ("font-size", "21px"),
      ("height", "24px")
    ]

-- Update
type alias Action = GithubEventSignal.SingleEvent

update: Action -> Model -> Model
update action model =
    case action of
        NothingYet -> model
        SoThisHappened event -> Model (List.take 10 (event :: model.recentEvents))
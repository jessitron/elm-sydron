module EventTicker(Model, init, view, update) where

import GithubEvent exposing (Event, EventActor)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events exposing (onMouseOver)
import SydronAction exposing (SydronAction(..))

-- Model

type alias Model = 
  {
    recentEvents : List Event,
    highlightPerson : Maybe EventActor
  }
init: Model 
init = 
  {
    recentEvents = [],
    highlightPerson = Nothing
  }
-- View

-- TODO: make watch events show as (String.fromChar '\x2b50')

type alias StylePortion = List (String, String)

eventListItem : (Event -> StylePortion) -> Signal.Address SydronAction -> Event -> Html
eventListItem howToHighlight addr event  =
    Html.div 
    [
      itemStyle (howToHighlight event),
      onMouseOver addr (PersonOfInterest event.actor)
    ]
    [Html.text (event.eventType ++ " by " ++ event.actor.login ++ " at " ++ event.created_at)]

view : Signal.Address SydronAction -> Model -> Html
view addr m =
  let
    howToHighlight event = 
      case m.highlightPerson of
        Nothing -> []
        Just ea ->
          if ea == event.actor then
            highlightStyle
          else
           []
  in
    Html.div
        [ divStyle ]
        (List.map (eventListItem howToHighlight addr) m.recentEvents)

highlightStyle = [("background-color", "gold")]

divStyle = 
  style 
    [  
      ("float", "left"),
      ("width", "50%"),
      ("box-sizing", "border-box"),
      ("color", "#666666"),
      ("overflow", "scroll"),
      ("padding", "10px")
    ]
itemStyle: StylePortion -> Html.Attribute
itemStyle highlight = 
  style 
    ([ 
      ("color", "#515151"),
      ("font-family", "Helvetica"),
      ("font-size", "21px"),
      ("height", "24px")
    ] ++ highlight)

-- Update
type alias Action = SydronAction

update: Action -> Model -> Model
update action model =
    case action of
        SingleEvent event -> { model | recentEvents <- (List.take 10 (event :: model.recentEvents)) }
        PersonOfInterest ea -> { model | highlightPerson <- Just ea }
        _ -> model





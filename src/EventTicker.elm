module EventTicker(Model, init, view, update) where

import GithubEvent exposing (Event, EventActor)
import Html exposing (..)
import Html.Attributes exposing (..)
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
    div
    [
      itemStyle (howToHighlight event),
      onMouseOver addr (PersonOfInterest event.actor)
    ]
    [text (event.eventType ++ " by " ++ event.actor.login ++ " at " ++ event.created_at)]


view : Signal.Address SydronAction -> Model -> Html
view addr m =
  div
      [ divStyle ]
      (List.map
        (eventListItem (eventHighlight m.highlightPerson) addr)
        m.recentEvents)


eventHighlight: Maybe EventActor -> Event -> StylePortion
eventHighlight whom event =
      case whom of
        Nothing -> []
        Just ea ->
          if ea == event.actor then
            highlightStyle
          else
           []


highlightStyle = ["background-color" => "gold"]


divStyle =
  style
    [
      "float" => "left",
      "width" => "50%",
      "box-sizing" => "border-box",
      "color" => "#666666",
      "overflow" => "scroll",
      "padding" => "10px"
    ]


(=>) = (,)


itemStyle: StylePortion -> Attribute
itemStyle highlight =
  style
    ([
      "color" => "#515151",
      "font-family" => "Helvetica",
      "font-size" => "21px"
    ] ++ highlight)


-- Update
type alias Action = SydronAction


update: Action -> Model -> Model
update action model =
  case action of
    SingleEvent event -> 
      { model 
        | recentEvents <- event :: model.recentEvents
      }
    PersonOfInterest ea -> 
      { model 
        | highlightPerson <- Just ea 
      }
    _ -> model




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
    [
      viewUser event.actor,
      span [] [viewEventType event.eventType],
      span [timestampStyle] [text event.created_at]
    ]


timestampStyle =
  -- TODO format the date and bump font-size back up
  style ["opacity" => "0.7", "font-size" => "10px", "margin-left" => "10px"]


viewUser user =
  a [ style ["font-family" => "monospace"],
      href ("https://github.com/" ++ user.login)
    ]
    [
      img [ src user.avatar_url, style [ "position" => "relative", "top" => "6px"], width 24 ] [],
      span [ style ["margin" => "0 10px"] ] [text user.login]
    ]


-- TODO: Full list of EventTypes is here: https://developer.github.com/v3/activity/events/types/
viewEventType eventType =
  span []
  [
    text <|
      case eventType of
        "PushEvent" ->
          "pushed code."

        "IssuesEvent" ->
          "created an issue."

        "PullRequestEvent" ->
          "created a pull request."

        unrecognizedEvent ->
          "did a " ++ unrecognizedEvent ++ "."
  ]

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
      "padding" => "5px 0",
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




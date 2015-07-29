module SeeThePeople where

import GithubEvent exposing (EventActor)
import Html exposing (Html)
import Html.Attributes as Attr

type alias Model = 
    { 
      allActors: List EventActor
    }

---- VIEW

draw: EventActor -> Html
draw actor = Html.img [Attr.src actor.avatar_url] []

view: Model -> Html
view model =
  Html.div [] (List.map draw model.allActors)

---- UPDATE

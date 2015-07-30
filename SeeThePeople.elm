module SeeThePeople(Model, init, view, update) where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (EventActor)
import GithubEventSignal exposing (SingleEvent(..))
import Html exposing (Html)
import Html.Attributes as Attr

type alias Model = 
    { 
      allActors: List EventActor
    }
init = Model []

---- VIEW

draw: EventActor -> Html
draw actor = Html.img [Attr.src actor.avatar_url , pictureStyle] []

view: Model -> Html
view model =
  Html.div [] (List.map draw model.allActors)

pictureStyle =
    Attr.style
     [
       ("padding", "20px"),
       ("width", "100px"),
       ("height", "100px")
     ]

---- UPDATE

type alias Action = SydronAction

update: Action -> Model -> Model
update a m = 
    case a of 
        TimeKeepsTickingAway t -> m
        SingleEvent NothingYet -> m
        SingleEvent (SoThisHappened e) -> 
            if List.member e.actor m.allActors
                then m
                else { m | allActors <- e.actor :: m.allActors }

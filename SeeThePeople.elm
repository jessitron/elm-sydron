module SeeThePeople(Model, init, view, update) where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (EventActor)
import GithubEventSignal exposing (SingleEvent(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Time exposing (Time)

type alias Percentage = Float

type Iteratee a = 
    Constantly a 
    | Varying (Time -> (a, Iteratee a))

type alias PresentAndFutureSize = 
    {
      present: Percentage,
      future: Iteratee Percentage
    }
fullSize = PresentAndFutureSize 1.0 (Constantly 1.0) 

type alias EachPerson = {
  actor: EventActor,
  size: PresentAndFutureSize
}

type alias Model = 
    { 
      all: List EachPerson  
    }
init = Model []
---- VIEW

draw: EachPerson -> Html
draw p = Html.img [Attr.src p.actor.avatar_url , pictureStyle p.size.present] []

view: Model -> Html
view model =
  Html.div [] (List.map draw model.all)

pictureStyle : Float -> Html.Attribute
pictureStyle relativeSize =
    Attr.style
     [
       ("padding-left", "20px"),
       ("padding-right", "20px"),
       ("padding-top", "20px"),
       ("padding-bottom", "20px"),
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
            if List.member e.actor (List.map .actor m.all)
                then m
                else { m | all <- (EachPerson e.actor fullSize) :: m.all }

-- animate



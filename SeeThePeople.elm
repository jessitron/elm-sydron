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

borderPx = 20
imgPx = 100

pictureStyle : Float -> Html.Attribute
pictureStyle relativeSize =
    Attr.style
     [
       ("padding-left", relativePixels borderPx relativeSize),
       ("padding-right", relativePixels borderPx relativeSize),
       ("padding-top", pixels borderPx),
       ("padding-bottom", pixels borderPx),
       ("width", relativePixels imgPx relativeSize),
       ("height", relativePixels imgPx relativeSize)
     ]

pixels: Int -> String
pixels i = (toString i) ++ "px"

relativePixels: Int -> Float -> String
relativePixels maxPx relativeSize = 
 (toFloat maxPx) * relativeSize
   |> round 
   |> pixels

---- UPDATE

type alias Action = SydronAction

update: Action -> Model -> Model
update a m = 
    case a of 
        TimeKeepsTickingAway t -> { m | all <- List.map (incrementSize t) m.all }
        SingleEvent NothingYet -> m
        SingleEvent (SoThisHappened e) -> 
            if List.member e.actor (List.map .actor m.all)
                then m
                else { m | all <- (EachPerson e.actor growing) :: m.all }

-- animate

incrementSize : Time -> EachPerson -> EachPerson
incrementSize t m =
  case m.size.future of 
   Constantly _ -> m
   Varying f    ->
     let
       (nextPresent, nextFuture) = f t
     in
       { m | size <- { present = nextPresent, future = nextFuture } }

slowness = Time.second

growing: PresentAndFutureSize
growing = 
  {
    present = 0.0,
    future = Varying (growFromOver slowness 0.0)
  }

growFromOver : Time -> Float -> Time -> (Float, Iteratee Float)
growFromOver totalTime presentValue dt = 
  let
    max = 1.0
    nextPresent = (dt / totalTime) * max + presentValue
    nextFunction = growFromOver totalTime nextPresent
  in
    if (nextPresent >= max)
    then (max, Constantly max)
    else (presentValue, Varying nextFunction)


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
  size: PresentAndFutureSize,
  border: PresentAndFutureSize
}
newPerson actor = EachPerson actor growing shrinking

type alias Model = 
    { 
      all: List EachPerson 
    }
init = Model []
---- VIEW

draw: EachPerson -> Html
draw p = Html.img [Attr.src p.actor.avatar_url , pictureStyle p.size.present p.border.present ] []

view: Model -> Html
view model =
  Html.div [] (List.map draw model.all)

marginPx = 20
imgPx = 100
maxBorderPx = 10

pictureStyle : Float -> Float -> Html.Attribute
pictureStyle relativeSize borderSize =
    Attr.style
     [
       ("margin-left", relativePixels marginPx relativeSize),
       ("margin-right", relativePixels marginPx relativeSize),
       ("margin-top", pixels marginPx),
       ("margin-bottom", pixels marginPx),
       ("width", relativePixels imgPx relativeSize),
       ("height", pixels imgPx),
       ("border", (relativePixels maxBorderPx borderSize) ++ " solid orange")
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
        TimeKeepsTickingAway t -> { m | all <- List.map (\m -> incrementSize t (incrementBorder t m)) m.all }
        SingleEvent NothingYet -> m
        SingleEvent (SoThisHappened e) -> 
            if List.member e.actor (List.map .actor m.all)
                then m
                else { m | all <- (newPerson e.actor) :: m.all }

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
incrementBorder t m =
  case m.border.future of 
   Constantly _ -> m
   Varying f    ->
     let
       (nextPresent, nextFuture) = f t
     in
       { m | border <- { present = nextPresent, future = nextFuture } }

entrySlowness = Time.second

growing: PresentAndFutureSize
growing = 
  {
    present = 0.0,
    future = Varying (growFromOver entrySlowness 0.0)
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

borderErodes = 3 * Time.second

shrinking: PresentAndFutureSize
shrinking = 
  {
    present = 1.0,
    future = Varying (shrinkOver borderErodes 1.0)
  }

shrinkOver : Time -> Float -> Time -> (Float, Iteratee Float)
shrinkOver totalTime presentValue dt = 
  let
    min = 0.0
    nextPresent = presentValue - (dt / totalTime) * 1.0
    nextFunction = shrinkOver totalTime nextPresent
  in
    if (nextPresent <= min)
    then (min, Constantly min)
    else (presentValue, Varying nextFunction)




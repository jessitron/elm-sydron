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
  let 
    borderPx = relative maxBorderPx borderSize
    horizontalMargin = pixels ((relative marginPx relativeSize) - borderPx)
    verticalMargin = pixels (marginPx - borderPx)
  in
    Attr.style
     [
       ("margin-left", horizontalMargin),
       ("margin-right", horizontalMargin),
       ("margin-top", verticalMargin),
       ("margin-bottom", verticalMargin),
       ("width", pixels (relative imgPx relativeSize)),
       ("height", pixels imgPx),
       ("border", (pixels borderPx) ++ " solid orange")
     ]

pixels: Int -> String
pixels i = (toString i) ++ "px"

relative: Int -> Float -> Int
relative maxPx relativeSize = 
 round ((toFloat maxPx) * relativeSize) 

---- UPDATE

type alias Action = SydronAction

update: Action -> Model -> Model
update a m = 
    case a of 
        TimeKeepsTickingAway t -> { m | all <- List.map (\m -> incrementSize t (incrementBorder t m)) m.all }
        SingleEvent NothingYet -> m
        SingleEvent (SoThisHappened e) -> 
            if List.member e.actor (List.map .actor m.all)
                then { m | all <- startAnimation e.actor m.all }
                else { m | all <- (newPerson e.actor) :: m.all }

-- animate

startAnimation : EventActor -> List EachPerson -> List EachPerson
startAnimation ea = 
  List.map (\n -> if (n.actor /= ea) then n else { n | border <- shrinking })


incrementSize : Time -> EachPerson -> EachPerson
incrementSize t m =
  { m | size <- iterateeate t m.size }
incrementBorder t m =
  { m | border <- iterateeate t m.border }

iterateeate : Time -> PresentAndFutureSize -> PresentAndFutureSize
iterateeate t paf =
  case paf.future of
    Constantly _ -> paf
    Varying f    ->
      let
        (nextPresent, nextFuture) = f t
      in
        PresentAndFutureSize nextPresent nextFuture

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




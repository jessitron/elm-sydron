module SeeThePeople(Model, init, view, update) where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (EventActor, Event)
import Html exposing (Html)
import Html.Attributes as Attr
import Time exposing (Time)

type alias Percentage = Float


type alias PresentAndFuture a = 
    {
      present: a,
      future: Iteratee a
    }

type Iteratee a = 
    Constant
    | Varying (Time -> PresentAndFuture a)


fullSize = PresentAndFuture 1.0 Constant 

type alias EachPerson = {
  actor: EventActor,
  size: PresentAndFuture Percentage,
  border: PresentAndFuture Percentage
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
  Html.div 
    [ divStyle ]
    (List.map draw model.all)

divStyle = 
  Attr.style
    [("float", "right"),
     ("width", "50%")]

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

update: SydronAction -> Model -> Model
update a model = 
    case a of 
        TimeKeepsTickingAway t -> { model | all <- List.map (\m -> incrementSize t (incrementBorder t m)) model.all }
        SingleEvent e -> 
            if List.member e.actor (List.map .actor model.all)
                then { model | all <- startAnimation e.actor model.all }
                else { model | all <- (newPerson e.actor) :: model.all }

-- animate

startAnimation : EventActor -> List EachPerson -> List EachPerson
startAnimation ea = 
  List.map (\n -> if (n.actor /= ea) then n else { n | border <- shrinking })


incrementSize : Time -> EachPerson -> EachPerson
incrementSize t m =
  { m | size <- iterateeate t m.size }
incrementBorder t m =
  { m | border <- iterateeate t m.border }

iterateeate : Time -> PresentAndFuture a -> PresentAndFuture a
iterateeate t paf =
  case paf.future of
    Constant  -> paf
    Varying f -> f t

entrySlowness = Time.second

growing: PresentAndFuture Percentage
growing = 
  {
    present = 0.0,
    future = Varying (growFromOver entrySlowness 0.0)
  }

growFromOver : Time -> Percentage -> Time -> PresentAndFuture Percentage
growFromOver totalTime presentValue dt = 
  let
    max = 1.0
    nextPresent = (dt / totalTime) * max + presentValue
    nextFunction = growFromOver totalTime nextPresent
  in
    if (nextPresent >= max)
    then PresentAndFuture max Constant
    else PresentAndFuture presentValue (Varying nextFunction)

borderErodes = 3 * Time.second

shrinking: PresentAndFuture Percentage
shrinking = 
  {
    present = 1.0,
    future = Varying (shrinkOver borderErodes 1.0)
  }

shrinkOver : Time -> Percentage -> Time -> PresentAndFuture Percentage
shrinkOver totalTime presentValue dt = 
  let
    min = 0.0
    nextPresent = presentValue - (dt / totalTime) * 1.0
    nextFunction = shrinkOver totalTime nextPresent
  in
    if (nextPresent <= min)
    then PresentAndFuture min Constant
    else PresentAndFuture presentValue (Varying nextFunction)





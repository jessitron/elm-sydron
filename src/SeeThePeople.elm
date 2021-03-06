module SeeThePeople(Model, init, view, update) where

import SydronAction exposing (SydronAction(..))
import GithubEvent exposing (EventActor, Event)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onMouseOver)
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


type Highlight =
  NoHighlight
  | PersonOfInterestHighlight


type alias EachPerson = {
  actor: EventActor,
  size: PresentAndFuture Percentage,
  border: PresentAndFuture Percentage,
  highlight: Highlight
}


newPerson actor =
  {
    actor = actor,
    size = growing,
    border = shrinking,
    highlight = NoHighlight
  }


type alias Model =
    {
      all: List EachPerson
    }


init = Model []


---- VIEW

draw: Signal.Address SydronAction -> EachPerson -> Html
draw addr p =
  img
    [
     src p.actor.avatar_url,
     personStyle p,
     onMouseOver addr (PersonOfInterest p.actor)
    ][]


view: Signal.Address SydronAction -> Model -> Html
view addr model =
  div
    [ divStyle ]
    (List.map (draw addr) model.all)


divStyle =
  style
    ["float" => "right",
     "width" => "50%"]


marginPx = 20


imgPx = 100


maxBorderPx = 10


personStyle: EachPerson -> Attribute
personStyle p =
  style (
    (highlightStyle p.highlight)
    ++ (pictureStyle p.size.present p.border.present)
    )


highlightStyle: Highlight -> List (String, String)
highlightStyle h =
  case h of
    NoHighlight -> []
    PersonOfInterestHighlight -> [("box-shadow", "10px 5px gold")]


pictureStyle : Float -> Float -> List (String, String)
pictureStyle relativeSize borderSize =
  let
    borderPx = relative maxBorderPx borderSize
    horizontalMargin = pixels ((relative marginPx relativeSize) - borderPx)
    verticalMargin = pixels (marginPx - borderPx)
  in
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
        TimeKeepsTickingAway t ->
          { model
            | all <- List.map (\m -> incrementSize t (incrementBorder t m)) model.all
          }
        SingleEvent e ->
            if List.member e.actor (List.map .actor model.all)
                then { model | all <- startAnimation e.actor model.all }
                else { model | all <- (newPerson e.actor) :: model.all }
        PersonOfInterest p ->
            highlightPerson p model

-- highlight
highlightPerson: EventActor -> Model -> Model
highlightPerson ea model =
  let
    shouldHighlight person = (person.actor == ea)
    correctHighlight person =
      if shouldHighlight person then
        PersonOfInterestHighlight
      else
        NoHighlight
  in
    { model
     | all <- List.map (\p -> { p | highlight <- correctHighlight p}) model.all
    }


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


(=>) = (,)

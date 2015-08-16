module GithubEventLayer(init, update, view, Action(..), wrapAction) where

import SydronInt as Inner
import SydronAction as InnerActions
import GithubEvent exposing (Event, BookmarkHeader, fetchPageOfEvents)
import GithubRepository exposing (GithubRepository)
import ErrorDisplay
--
import Effects exposing (Effects)
import Task exposing (Task)
import Http
import Html exposing (Html)

--- ACTIONS

type alias InnerAction = InnerActions.SydronAction
passSingleEvent: Event -> InnerAction
passSingleEvent e = InnerActions.SingleEvent e

type Action = Passthrough InnerAction
             | Heartbeat
             | SomeNewEvents (List Event) BookmarkHeader
             | ErrorAlert Http.Error

wrapAction: InnerAction -> Action
wrapAction ia = Passthrough ia

--- MODEL

type alias InnerModel = Inner.Model 

type alias Model =    
    { 
      inner: InnerModel,
      repository: GithubRepository,
      seen: List Event, 
      unseen: List Event,
      lastError: Maybe Http.Error,
      lastHeader: Maybe BookmarkHeader
    }

--innerInit: GithubRepository -> Inner.Model
innerInit = Inner.init
 
init: GithubRepository -> (Model, Effects Action) 
init repo = 
    (
      { inner = innerInit repo,
        repository = repo,
        seen = [],
        unseen = [],
        lastHeader = Nothing,
        lastError = Nothing
      },
      fetchEvents repo Nothing
    )

--- UPDATE

type alias InnerUpdate = InnerAction -> Inner.Model -> Inner.Model
innerUpdate: InnerUpdate
innerUpdate = Inner.update 

update: Action -> Model -> (Model, Effects Action)
update a = updateModel a >> andDoNothing

updateModel: Action -> Model -> Model
updateModel a m =
  case a of 
    Passthrough ia -> { m | inner <- innerUpdate ia m.inner }
    SomeNewEvents moreEvents bh -> { m | unseen <- m.unseen ++ (List.reverse moreEvents),
                                         lastHeader <- Just bh }
    Heartbeat -> 
      case m.unseen of
        [] -> m
        head :: tail -> { m | inner <- innerUpdate (passSingleEvent head) m.inner,
                              seen <- head :: m.seen, 
                              unseen <- tail }
    ErrorAlert e -> { m | lastError <- Just e}

andDoNothing: Model -> (Model, Effects Action)
andDoNothing m = (m, Effects.none)


--- EFFECTS 

fetchEvents: GithubRepository -> Maybe BookmarkHeader -> Effects Action
fetchEvents repo bh = wrapErrors (fetchPageOfEvents repo bh)

--- guts

errorToAction: Http.Error -> Task Effects.Never Action
errorToAction e = Task.succeed (ErrorAlert e)

wrapErrors: Task Http.Error ((List Event), BookmarkHeader) -> Effects Action
wrapErrors t =
  t 
  |> Task.map someNewEvents
  |> (\t -> Task.onError t errorToAction)
  |> Effects.task

someNewEvents (ee, bh) = SomeNewEvents ee bh

view: Signal.Address Action -> Model -> Html
view addr m = Html.div [] 
                [
                  Inner.view (Signal.forwardTo addr Passthrough ) m.inner,
                  ErrorDisplay.view m.lastError
                ]















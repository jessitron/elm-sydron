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
      error: Maybe Http.Error,
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
        error = Nothing
      },
      fetchEvents repo Nothing
    )

--- UPDATE

type alias InnerUpdate = InnerAction -> Inner.Model -> Inner.Model
innerUpdate: InnerUpdate
innerUpdate = Inner.update 

update: Action -> Model -> (Model, Effects Action)
update a m =
  case m.error of 
    Just anything -> m `andDo` Nothing -- do nothing if we have ever failed
    Nothing ->
    case a of 
      Passthrough ia -> { m | inner <- innerUpdate ia m.inner } `andDo` Nothing
      SomeNewEvents moreEvents bh -> { m | unseen <- m.unseen ++ (List.reverse moreEvents),
                                           lastHeader <- Just bh } `andDo` Nothing
      Heartbeat -> 
        case m.unseen of
          [] -> m `andDo` Just (fetchEvents m.repository m.lastHeader)
          head :: tail -> { m | inner <- innerUpdate (passSingleEvent head) m.inner,
                                seen <- head :: m.seen, 
                                unseen <- tail } `andDo` Nothing
      ErrorAlert e -> { m | error <- Just e} `andDo` Nothing

andDo: Model -> Maybe (Effects Action) -> (Model, Effects Action)
andDo m maybe =
  case maybe of
    Nothing -> (m, Effects.none)
    Just something -> (m, something)


--- EFFECTS 

fetchEvents: GithubRepository -> Maybe BookmarkHeader -> Effects Action
fetchEvents repo bh = wrapErrors bh (fetchPageOfEvents repo bh)

--- guts

errorToAction: Http.Error -> Task Effects.Never Action
errorToAction e = Task.succeed (ErrorAlert e)

notModifiedIsOk: Maybe BookmarkHeader -> Http.Error -> Task Http.Error ((List Event), BookmarkHeader)
notModifiedIsOk mbh e =
  case (mbh, e) of
    (Just bh, Http.BadResponse 304 _) -> Task.succeed ([], bh)
    (_, e) -> Task.fail e

wrapErrors: Maybe BookmarkHeader -> Task Http.Error ((List Event), BookmarkHeader) -> Effects Action
wrapErrors mbh t =
  t 
  |> (\t -> Task.onError t (notModifiedIsOk mbh))
  |> Task.map someNewEvents
  |> (\t -> Task.onError t errorToAction)
  |> Effects.task

someNewEvents (ee, bh) = SomeNewEvents ee bh

view: Signal.Address Action -> Model -> Html
view addr m = Html.div [] 
                [
                  Inner.view (Signal.forwardTo addr Passthrough ) m.inner,
                  ErrorDisplay.view m.error
                ]















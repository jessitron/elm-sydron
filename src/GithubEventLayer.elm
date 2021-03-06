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
import Html exposing (..)


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
  case a of
    Passthrough ia ->
      { m | inner <- innerUpdate ia m.inner } => Effects.none

    SomeNewEvents moreEvents bh ->
      { m |
        unseen <- m.unseen ++ (List.reverse (filterKnown m moreEvents)),
        lastHeader <- Just bh
      } => Effects.none

    Heartbeat ->
      case m.unseen of
        [] ->
          case m.error of
            Just anything ->
              m => Effects.none -- do nothing if we have ever failed

            Nothing ->
              m => fetchEvents m.repository m.lastHeader

        head :: tail ->
          { m |
            inner <- innerUpdate (passSingleEvent head) m.inner,
            seen <- head :: m.seen,
            unseen <- tail
          } => Effects.none

    ErrorAlert e ->
      { m | error <- Just e} => Effects.none


{- Micro-DSL for creating tuples. Now these are equivalent:

foo => bar
(foo, bar)

-}
(=>) = (,)


filterKnown: Model -> List Event -> List Event
filterKnown m incomingEvents =
  let
    isKnown event =
      m.seen ++ m.unseen
        |> List.member event
  in
    incomingEvents
      |> List.filter (not << isKnown)


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
view addr m = div []
                [
                  Inner.view (Signal.forwardTo addr Passthrough ) m.inner,
                  ErrorDisplay.view m.error
                ]

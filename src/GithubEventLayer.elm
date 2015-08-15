module GithubEventLayer(init, update, view, Action) where

import SydronInt as Inner
import SydronAction as InnerActions
import GithubEvent exposing (Event)
import GithubRepository exposing (GithubRepository)
--
import Effects exposing (Effects)
import Task exposing (Task)
import Http

--- ACTIONS

type InnerAction = InnerActions.SydronAction -- this isn't working anymore
passSingleEvent: Event -> InnerActions.SydronAction
passSingleEvent e = InnerActions.ThisHappened e

type Action = Passthrough InnerActions.SydronAction
             | Heartbeat
             | SomeNewEvents (List Event)
             | ErrorAlert Http.Error

--- MODEL

type InnerModel = Inner.Model -- wish I could do this
type LastSeenHeader = String
type alias Model =    
    { 
      inner: Inner.Model,
      repository: GithubRepository,
      seen: List Event, 
      unseen: List Event,
      lastHeader: Maybe LastSeenHeader
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
        lastHeader = Nothing
      },
      fetchEvents repo Nothing
    )

--- UPDATE

--innerUpdate: InnerAction -> Inner.Model -> Inner.Model
innerUpdate = Inner.update 

update: Action -> Model -> (Model, Effects Action)
update a = updateModel a >> andDoNothing

updateModel: Action -> Model -> Model
updateModel a m =
  case a of 
    Passthrough ia -> { m | inner <- innerUpdate ia m.inner }
    SomeNewEvents moreEvents -> { m | unseen <- m.unseen ++ moreEvents }
    Heartbeat -> moveOneOver m

andDoNothing: Model -> (Model, Effects Action)
andDoNothing m = (m, Effects.none)
 
moveOneOver : Model -> Model
moveOneOver before = 
    case before.unseen of 
        [] -> before
        head :: tail -> { before | seen <- head :: before.seen, unseen <- tail }

--- EFFECTS 

fetchEvents: GithubRepository -> Maybe LastSeenHeader -> Effects Action
fetchEvents repo Nothing = wrapErrors (fetchPageOfEvents repo)

--- guts
fetchPageOfEvents : GithubRepository -> Task Http.Error (List Event)
fetchPageOfEvents repo =
    let
      pageNo = 1
      parameters = [("page", toString pageNo)]
    in 
      Http.get GithubEvent.listDecoder (github repo pageNo)

realGithubUrl = "https://api.github.com/repos"

github : GithubRepository -> Int -> String
github repo pageNo = Http.url ( (Maybe.withDefault realGithubUrl repo.githubUrl) ++ "/" ++ repo.owner ++ "/" ++ repo.repo ++ "/events") <|
        [("pageNo", (toString pageNo))]

errorToAction: Http.Error -> Task Effects.Never Action
errorToAction e = Task.succeed (ErrorAlert e)

wrapErrors: Task Http.Error (List Event) -> Effects Action
wrapErrors t =
  t 
  |> Task.map SomeNewEvents
  |> (\t -> Task.onError t errorToAction)
  |> Effects.task

view = "hi"















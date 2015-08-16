module GithubEvent (EventActor, Event, BookmarkHeader, fetchPageOfEvents) where

import Json.Decode as Json exposing ((:=))
import Date exposing (Date)
import GithubRepository exposing (GithubRepository)
import Http
import Task exposing (Task)


-- JSON DECODERS

type alias EventActor = 
    { 
      login: String,
      avatar_url: String
    }

type alias Event = 
  {
    eventType : String,
    actor : EventActor,
    created_at: String
  }

githubEventActor : Json.Decoder EventActor
githubEventActor = 
    Json.object2
      EventActor
        ("login" := Json.string)
        ("avatar_url" := Json.string)

listDecoder : Json.Decoder (List Event)
listDecoder =
    Json.list <| 
        Json.object3
          Event
          ("type" := Json.string)
          ("actor" := githubEventActor)
          ("created_at" := Json.string)

--- HOW TO FETCH

type alias BookmarkHeader = 
  {
    eTag: String
  }

fetchPageOfEvents : GithubRepository -> Maybe BookmarkHeader -> Task Http.Error ((List Event), BookmarkHeader)
fetchPageOfEvents repo _ =
    let
      pageNo = 1
      parameters = [("page", toString pageNo)]
    in 
      Http.get listDecoder (github repo pageNo)
      |> Task.map (\e -> (e, { eTag = "" }))

realGithubUrl = "https://api.github.com/repos"

github : GithubRepository -> Int -> String
github repo pageNo = Http.url ( (Maybe.withDefault realGithubUrl repo.githubUrl) ++ "/" ++ repo.owner ++ "/" ++ repo.repo ++ "/events") <|
        [("pageNo", (toString pageNo))]
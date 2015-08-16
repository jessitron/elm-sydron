module GithubEvent (EventActor, Event, BookmarkHeader, fetchPageOfEvents) where

import Json.Decode as Json exposing ((:=))
import Date exposing (Date)
import GithubRepository exposing (GithubRepository)
import Http
import Task exposing (Task)
import GetWithHeaders
import Dict

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

type alias BookmarkHeader = String

fetchPageOfEvents : GithubRepository -> Maybe BookmarkHeader -> Task Http.Error ((List Event), BookmarkHeader)
fetchPageOfEvents repo bh =
    let
      headers = Maybe.map (\s -> [("If-None-Match", s)]) bh |> Maybe.withDefault [] 
    in 
      GetWithHeaders.get listDecoder (github repo 1) headers
      |> Task.map extractHeader

realGithubUrl = "https://api.github.com/repos"

extractHeader: (value, GetWithHeaders.Headers) -> (value, BookmarkHeader)
extractHeader (v, hh) = 
  let 
    dict = (Dict.fromList hh)
    getOrEmpty key = (Dict.get key) >> Maybe.withDefault ""
  in
    (v, getOrEmpty "ETag" dict)

github : GithubRepository -> Int -> String
github repo pageNo = Http.url ( (Maybe.withDefault realGithubUrl repo.githubUrl) ++ "/" ++ repo.owner ++ "/" ++ repo.repo ++ "/events") <|
        [("pageNo", (toString pageNo))]


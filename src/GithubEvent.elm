module GithubEvent (EventActor, Event, listDecoder) where

import Json.Decode as Json exposing ((:=))
import Date exposing (Date)


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
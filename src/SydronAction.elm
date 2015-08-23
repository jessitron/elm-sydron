module SydronAction(SydronAction(..)) where

import Time exposing (Time)
import GithubEvent exposing (Event, EventActor)

type SydronAction = 
  SingleEvent Event 
  | TimeKeepsTickingAway Time 
  | PersonOfInterest EventActor

module SydronAction(SydronAction(..)) where

import Time exposing (Time)
import GithubEvent exposing (Event)

type SydronAction = SingleEvent Event | TimeKeepsTickingAway Time

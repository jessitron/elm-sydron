module SydronAction(SydronAction(..)) where

import GithubEventSignal
import Time exposing (Time)
import GithubEvent exposing (Event)

type SydronAction = SingleEvent GithubEventSignal.SingleEvent | TimeKeepsTickingAway Time | ThisHappened Event

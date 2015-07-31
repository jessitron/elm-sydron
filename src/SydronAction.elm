module SydronAction(SydronAction(..)) where

import GithubEventSignal
import Time exposing (Time)

type SydronAction = SingleEvent GithubEventSignal.SingleEvent | TimeKeepsTickingAway Time 

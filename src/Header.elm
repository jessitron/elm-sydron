module Header(view) where

import GithubRepository exposing (GithubRepository)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model = GithubRepository


view model =
  div
    [ style
      [
        "font-family" => "Helvetica",
        "margin-top" => "20px",
        "margin-left" => "20px"
      ]
    ]
  [
    h1 [] [text "Sydron: A Parade of GitHub Events"],
    p [] [
      text "This retrieves one page of past events (within the past 90 days; GitHub doesn’t keep them forever) and displays them one at a time. Then it polls for new events for the repository, displaying them as they come in. Events are displayed at most one per three seconds."
    ],
    p [] [
      text "This is me playing with ",
      a [href "http://elm-lang.org"] [text "Elm"],
      text "; source code ",
      a [href "http://github.com/jessitron/elm-sydron"] [text "here"],
      text "."
    ]
  ]


(=>) = (,)

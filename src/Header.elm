module Header(view) where

import GithubRepository exposing (GithubRepository)
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model = GithubRepository


view model =
  div
    [ style
      [
        "height" => "100px",
        "font-family" => "Helvetica",
        "margin-top" => "20px",
        "margin-left" => "20px"
      ]
    ]
  [
    h1 []
      [text "Sydron"],
    text "A parade of Github Events for ",
    a [href (repositoryLink model) ] [ text (repositoryDescription model)],
    text ". This is me playing with Elm; source code ",
    a [href "http://github.com/jessitron/elm-sydron"] [ text "here" ],
    text ".",
    br [] [],
    text "This retrieves one page of past events (within the past 90 days; github doesn't keep them forever)",
    text " and displays them one at a time. Then it polls github for new events for the repository, displaying them as they come in.",
    text " Events are displayed at most one per three seconds."
  ]


repositoryLink repo = "http://github.com/" ++ repo.owner ++ "/" ++ repo.repo
repositoryDescription repo = repo.owner ++ "'s " ++ repo.repo ++ " repository"

(=>) = (,)

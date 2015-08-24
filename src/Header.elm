module Header(view) where

import GithubRepository exposing (GithubRepository)
import Html
import Html.Attributes as Attr


type alias Model = GithubRepository


view model =
  Html.div
    [ Attr.style
      [
        ("height", "100px"),
        ("font-family", "Helvetica"),
        ("margin-top", "20px"),
        ("margin-left", "20px")
      ]
    ]
  [
    Html.h1 []
      [Html.text "Sydron"],
    Html.text "A parade of Github Events for ",
    Html.a [Attr.href (repositoryLink model) ] [ Html.text (repositoryDescription model)],
    Html.text ". This is me playing with Elm; source code ",
    Html.a [Attr.href "http://github.com/jessitron/elm-sydron"] [ Html.text "here" ],
    Html.text ".",
    Html.br [] [],
    Html.text "This retrieves one page of past events (within the past 90 days; github doesn't keep them forever)",
    Html.text " and displays them one at a time. Then it polls github for new events for the repository, displaying them as they come in.",
    Html.text " Events are displayed at most one per three seconds."
  ]


repositoryLink repo = "http://github.com/" ++ repo.owner ++ "/" ++ repo.repo
repositoryDescription repo = repo.owner ++ "'s " ++ repo.repo ++ " repository"

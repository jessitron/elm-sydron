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
    Html.text "."
  ]

repositoryLink repo = "http://github.com/" ++ repo.owner ++ "/" ++ repo.repo
repositoryDescription repo = repo.owner ++ "'s " ++ repo.repo ++ " repository"
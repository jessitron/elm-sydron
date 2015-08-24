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
    h2 [] 
    [
      text "A parade of Github Events for ",
      a [href (repositoryLink model) ] [ text (repositoryLink model)]
    ]
  ]


repositoryLink repo = "http://github.com/" ++ repo.owner ++ "/" ++ repo.repo
repositoryDescription repo = repo.owner ++ "'s " ++ repo.repo ++ " repository"

(=>) = (,)

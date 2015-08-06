module RepoInput(view) where

import Html exposing (Html)
import Html.Attributes as Attr
import GithubRepository exposing (GithubRepository)

view : String -> GithubRepository -> Html
view formclass repo = 
  Html.div []
    [ Html.form [ Attr.style [("class", formclass)]] [
       Html.input [ Attr.placeholder "owner", Attr.name "owner", Attr.value repo.owner] [],
       Html.input [ Attr.placeholder "repository", Attr.name "repo-name", Attr.value repo.repo] [],
       Html.button [ Attr.style [("background", "url('img/elm-button.jpg')"), ("width", "137px"), ("height", "100px")]] [Html.text "Go"]
    ]]
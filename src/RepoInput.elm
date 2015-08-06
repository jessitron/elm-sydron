module RepoInput(view) where

import Html exposing (Html)
import Html.Attributes as Attr

view : String -> Html
view formclass = 
  Html.div []
    [ Html.form [ Attr.style [("class", formclass)]] [
       Html.input [ Attr.placeholder "owner", Attr.name "owner"] [],
       Html.input [ Attr.placeholder "repository", Attr.name "repo-name"] [],
       Html.button [ Attr.style [("background", "url('img/elm-button.jpg')"), ("width", "137px"), ("height", "100px")]] [Html.text "Go"]
    ]]
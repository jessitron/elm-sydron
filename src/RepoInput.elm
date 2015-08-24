module RepoInput(view) where

import Html exposing (..)
import Html.Attributes exposing (..)


view : String -> Html
view formclass =
  div [ styles ]
    [ Html.form [ class formclass] [
      fieldset [] [
         legend [] [text "See events for a different repository:"],
         input [ placeholder "owner", name "owner"] [],
         input [ placeholder "repository", name "repo-name"] [],
         button [ class "pure-button pure-button-primary"] [text "Go"]
       ]
    ]]


styles : Attribute
styles = style [
          "margin" => "10px"
          ]

(=>) = (,)

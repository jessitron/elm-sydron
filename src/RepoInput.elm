module RepoInput(view) where

import Html exposing (Html)
import Html.Attributes as Attr

view : String -> Html
view formclass = 
  Html.div [ styles ]
    [ Html.form [ Attr.class formclass] [
      Html.fieldset [] [
         Html.legend [] [Html.text "See events for a different repository:"],
         Html.input [ Attr.placeholder "owner", Attr.name "owner"] [],
         Html.input [ Attr.placeholder "repository", Attr.name "repo-name"] [],
         Html.button [ Attr.class "pure-button pure-button-primary"] [Html.text "Go"]
       ]
    ]]

styles : Html.Attribute
styles = Attr.style [
          ("margin", "10px")
          ]

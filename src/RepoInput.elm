module RepoInput(view) where

import Html exposing (..)
import Html.Attributes exposing (..)

view : String -> String -> String -> Html
view formclass owner repo =
  Html.form [ class formclass, style [ "margin" => "20px" ]] [
    fieldset [] [
      section [ formElemStyle ] [
         label [ for "owner-input", labelStyle ] [ text "Owner:" ],
         input [ id "owner-input", inputStyle, placeholder owner, name "owner"] []
      ],

      section [ formElemStyle ] [
         label [ for "repo-input", labelStyle ] [ text "Repository:" ],
         input [ id "repo-input", inputStyle, placeholder repo, name "repo-name"] []
      ],

      button [ formElemStyle, class "pure-button pure-button-primary"]
        [text "Change Repository"]
    ]
  ]


formElemStyle =
  style [ "display" => "inline-block", "margin-right" => "20px" ]


labelStyle =
  style [ "display" => "block" ]


inputStyle =
  style [ "font-family" => "monospace" ]


(=>) = (,)

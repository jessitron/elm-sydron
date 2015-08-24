module ErrorDisplay(view) where

import Http
import Html exposing (..)
import Html.Attributes exposing (..)


view: Maybe Http.Error -> Html
view me =
 case me of
  Just e -> h2 [errorStyle] [text (toString e)]
  Nothing -> div [][]


errorStyle: Attribute
errorStyle = style [("color" => "red")]


(=>) = (,)

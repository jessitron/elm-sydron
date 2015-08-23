module ErrorDisplay(view) where

import Http
import Html exposing (Html, Attribute)
import Html.Attributes as Attr

view: Maybe Http.Error -> Html
view me =
 case me of
  Just e -> Html.h2 [errorStyle] [Html.text (toString e)]
  Nothing -> Html.div [][]

errorStyle: Attribute
errorStyle = Attr.style [("color", "red")]

module ParseUrlParams(parse) where

import String
import Dict exposing (Dict)

type Model = 
    Error String
  | UrlParams (Dict String String)


{-| Return a dictionary of URL params; in case of error, returns empty Dict -}
parse : String -> Dict String String
parse s =
  case (parseSearchString s) of
    UrlParams d -> d
    _ -> Dict.empty 


parseSearchString : String -> Model
parseSearchString startsWithQuestionMarkThenParams =
  case (String.uncons startsWithQuestionMarkThenParams) of
    Nothing -> Error "No URL params"
    Just ('?', rest) -> parseParams rest

parseParams : String -> Model
parseParams stringWithAmpersands =
  let
    eachParam = (String.split "&" stringWithAmpersands)
    eachPair  = List.map (splitAtFirst '=') eachParam
  in
    UrlParams (Dict.fromList eachPair)

splitAtFirst : Char -> String -> (String, String)
splitAtFirst c s =
  case (firstOccurrence c s) of
    Nothing -> (s, "")
    Just i  -> ((String.left i s), (String.dropLeft (i + 1) s))

firstOccurrence : Char -> String -> Maybe Int 
firstOccurrence c s = 
  case (String.indexes (String.fromChar c) s) of
    []        -> Nothing
    head :: _ -> Just head
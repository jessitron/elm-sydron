module GetWithHeaders(get, Headers) where

import Http exposing (send, empty, defaultSettings
    , Response, Value(..)
    , Error(..), RawError(..))
import Task exposing (Task, andThen, mapError, succeed, fail)
import Json.Decode as Json
import Dict exposing (Dict)


type alias Headers = List (String, String)


get: Json.Decoder value -> String -> Headers -> Task Error (value, Headers)
get decoder url headers =
  let
    request =
      {
          verb = "GET",
          headers = headers,
          url =  url,
          body = Http.empty
      }
    in
      fromJsonWithHeaders decoder (send defaultSettings request)


fromJsonWithHeaders : Json.Decoder a -> Task RawError Response -> Task Error (a, Headers)
fromJsonWithHeaders decoder response =
  let decode str =
        case Json.decodeString decoder str of
          Ok v -> succeed v
          Err msg -> fail (UnexpectedPayload msg)
  in
      mapError promoteError response
        `andThen` handleResponseWithHeaders decode


promoteError : RawError -> Error
promoteError rawError =
  case rawError of
    RawTimeout -> Timeout
    RawNetworkError -> NetworkError


handleResponseWithHeaders : (String -> Task Error a) -> Response -> Task Error (a, Headers)
handleResponseWithHeaders handle response =
  case 200 <= response.status && response.status < 300 of
    False ->
        fail (BadResponse response.status response.statusText)

    True ->
        case response.value of
          Text str -> handle str |> Task.map (\v -> (v, (Dict.toList response.headers)))
          _ -> fail (UnexpectedPayload "Response body is a blob, expecting a string.")

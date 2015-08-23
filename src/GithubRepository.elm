module GithubRepository where

import Dict exposing (Dict)

type alias GithubRepository =
  {
    owner: String,
    repo : String,
    githubUrl : Maybe String
  }

fromDict: Dict String String -> String -> String -> GithubRepository
fromDict mappydoober defaultOwner defaultRepo =
  GithubRepository
        (Maybe.withDefault defaultOwner (Dict.get "owner" mappydoober))
        (Maybe.withDefault defaultRepo (Dict.get "repo-name" mappydoober))
        (Dict.get "github" mappydoober)

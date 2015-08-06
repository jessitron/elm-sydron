module GithubRepository where

type alias GithubRepository = 
  {
    owner: String,
    repo : String,
    githubUrl : Maybe String
  }
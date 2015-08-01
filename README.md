# Sydron: github events visualized
Hey, it's a start. Mostly I'm playing around with Elm.

## See it in action

Visit [Sydron](http://jessitron.github.io/elm-sydron), and type your
repository's owner and name into the form to see a replay of some
events.

## Run it yourself

To run this, install [Elm](http://elm-lang.org), then

    elm-package install
    elm-make *.elm
    open index.html

## What does it do

The program hits the Github events API for the repo, retrieves a page of
events, and then plays them back one at a time.

The person who triggered the events gets their picture on the screen,
and it's highlighted for each event they triggered.

## What is the point
You can't see it yet, but the goal is for people to see what's going on
in their organization, and get an idea that developers are working, and
what they're working on. It works equally well for remote as in-office
work.

SYD in Sydron stands for Survey Your Domain. It comes from this user
story: "As a Director, I want to look out over the cube walls and see
all the people diligently working for me." Can we get the same feeling
without requiring everyone to drive to an office daily?

The other use cases are more personal: "As a member of a remote team, I
want situational awareness - who is working on what with whom? Who might
be interruptible when I need help? Who might know about this topic?" In
an office, we get some of this awareness, but we could get more.

Currently the app hits the Github API only. It's easy, and a good start.
It will be more useful if it brings in Trello, Slack, Zoom
(somehow), Google Calendar. With a little deliberate communication, we could get much better situational awareness than an office gives us.

But for now, I'm playing with Elm :-)

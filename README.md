# GFF - Github Feed Filter

## Motivation
This is a simple web application based on sinatra and redis to show a filtered
form of your github feed. With more and more watched repositories, the news
feed gets more and more unclear. This is an attempt to fix this.

## Dependencies
- Ruby
- Sinatra
- Redis
- Mustache
- Yajl-json

## Security
The application asks for your github token and stores it in the browser's local
storage as a cookie. This means I could potentially steal your token and
comment all over the place with your github account. Unfortunately there is no
other way to retrieve the news feed at the moment (to my knowledge) and I
intend to change this as soon as possible. In the meanwhile you either have to
trust that the same version of the application shown here is running on heroku
or run your own.

## Contribute
Just fork and contribute, there are no tests at the moment, so you have to make
sure yourself you don't break it. Bonus points for topic branches (and creating
tests).

## Thanks
- [hckrnews](http://hckrnews.com/) for interface inspiration

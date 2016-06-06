require "sinatra"
require "pg"
require "pry"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/actors" do
  @actors = db_connection { |conn| conn.exec("SELECT name, id FROM actors ORDER BY name LIMIT 50")}
  erb :'actors/index'
end

get "/actors/:id" do
  id = params["id"]
  @actor_movie = db_connection do |conn|
    conn.exec(%(SELECT actors.name, movies.id, movies.title, cast_members.character FROM actors
    JOIN cast_members ON actors.id = cast_members.actor_id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE actors.id = #{id}))
  end
  erb :'actors/show'
end

get "/movies" do

  @movies = db_connection do |conn|
    conn.exec(%(SELECT movies.title, movies.id, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    LIMIT 50))
  end
  erb :'movies/index'
end

get "/movies/:id" do
  m_id = params["id"]
  @movie_actor= db_connection do |conn|
    conn.exec(%(SELECT movies.title, genres.name AS genre, studios.name AS studio,
    actors.name AS actors, cast_members.character, actors.id, movies.year, movies.rating
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = #{m_id}))
  end
  erb :'movies/show'
end

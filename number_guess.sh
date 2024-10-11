#!/bin/bash

# Function to check if the username exists in the database and retrieve games played and best game
check_user() {
  PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
  games_played=$($PSQL "SELECT COUNT(*) FROM guesses WHERE username = '$username';")
  best_game=$($PSQL "SELECT MIN(guesses) FROM (SELECT guess FROM guesses WHERE username = '$username' GROUP BY guess) AS subquery;")
  if [[ $games_played -gt 0 ]]; then
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  else
    echo "Welcome, $username! It looks like this is your first time here."
  fi
}

# Function to validate if the input is an integer
is_integer() {
  local re='^[-+]?[0-9]+$'
  if [[ $1 =~ $re ]]; then
    return 0 # return true
  else
    return 1 # return false
  fi
}

# Function to check the user's guess
check_guess() {
  local secret_number=$(( RANDOM % 1000 + 1 ))
  local number_of_guesses=0
  local user_guess

  echo "Guess the secret number between 1 and 1000:"
  while true; do
    read -r user_guess
    if ! is_integer "$user_guess"; then
      echo "That is not an integer, guess again:"
      continue
    fi

    ((number_of_guesses++))
    if [[ $user_guess -eq $secret_number ]]; then
      echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
      # Update the database with the new game
      $PSQL "INSERT INTO games (username, guesses) VALUES ('$username', $number_of_guesses);"
      break
    elif [[ $user_guess -lt $secret_number ]]; then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
  done
}

# Main game loop
while true; do
  read -p "Enter your username: " username
  # Create the database if it doesn't exist
  if ! psql --username=freecodecamp --dbname=postgres -t --no-align -c "SELECT 1 FROM pg_database WHERE datname = 'number_guess'" | grep -q 1; then
    psql --username=freecodecamp --dbname=postgres -c "CREATE DATABASE number_guess;"
  fi

  # Create the table if it doesn't exist
  PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
  if ! $PSQL "SELECT 1 FROM pg_tables WHERE tablename = 'guesses'" | grep -q 1; then
    $PSQL "CREATE TABLE guesses (id SERIAL PRIMARY KEY, username VARCHAR(22), guess INT);"
  fi

  if ! $PSQL "SELECT 1 FROM pg_tables WHERE tablename = 'games'" | grep -q 1; then
    $PSQL "CREATE TABLE games (id SERIAL PRIMARY KEY, username VARCHAR(22), guesses INT);"
  fi

  # Check if the username exists and print the appropriate welcome message
  check_user

  # Start the guessing game
  check_guess

  read -p "Do you want to play again? (y/n) " play_again
  if [[ $play_again != "y" ]]; then
    break
  fi
done
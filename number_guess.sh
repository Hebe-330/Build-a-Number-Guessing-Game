#!/bin/bash

# 定义 PostgreSQL 连接变量
PSQL="psql --username=freecodecamp --dbname=number_guess"

# 函数：检查用户名是否存在，并获取游戏次数和最佳成绩
check_user() {
  local username=$1
  games_played=$($PSQL -t --no-align -c "SELECT COUNT(*) FROM games WHERE user_id IN (SELECT user_id FROM users WHERE username = '$username');")
  best_game=$($PSQL -t --no-align -c "SELECT MIN(guess_count) FROM games WHERE user_id IN (SELECT user_id FROM users WHERE username = '$username');")

  if [ "$games_played" -gt 0 ]; then
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  else
    echo "Welcome, $username! It looks like this is your first time here."
    # 如果是新用户，插入到 users 表
    $PSQL -c "INSERT INTO users (username) VALUES ('$username');"
  fi
}

# 函数：检查输入是否为整数
is_integer() {
  local re='^[-+]?[0-9]+$'
  if [[ $1 =~ $re ]]; then
    return 0 # 是整数
  else
    return 1 # 不是整数
  fi
}

# 主游戏循环
while true; do
  read -p "Enter your username: " username
  check_user "$username"

  # 生成随机数
  secret_number=$(( RANDOM % 1000 + 1 ))
  number_of_guesses=0

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
      # 获取 user_id
      user_id=$($PSQL -t --no-align -c "SELECT user_id FROM users WHERE username = '$username';")
      # 插入游戏记录到 games 表
      $PSQL -c "INSERT INTO games (user_id, guess_count) VALUES ($user_id, $number_of_guesses);"
      break
    elif [[ $user_guess -lt $secret_number ]]; then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
  done

  read -p "Do you want to play again? (y/n): " play_again
  if [[ $play_again != "y" ]]; then
    break
  fi
done
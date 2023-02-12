#! /bin/sh

# DBサーバーに接続できることを確認してから立ち上げるように設定する。
if [ -n "${MONGODB_HOSTS}" ]; then
  node ./lib/database/wait.js
else
  echo "WARN: MONGODB_HOSTS is not defines."
fi

exec "$@"

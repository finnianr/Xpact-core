
cat $1  | grep -v -E "^(TAG|[Tt]ag)" | grep -v '^$'

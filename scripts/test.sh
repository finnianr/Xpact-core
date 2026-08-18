
# Throwaway test

find "/media/finnian/Windows/Windows/WinSxS" -type f 2>/dev/null | wc -l

find "/media/finnian/Windows/Windows/WinSxS" -type f -print0 2>/dev/null | \
while IFS= read -r -d '' f; do
	v=$(getfattr -n system.ntfs_attrib --only-values "$f" 2>/dev/null | od -An -tu4 --endian=little | tr -d ' ')
	[[ -n "$v" ]] && (( (v & 0x40000) || (v & 0x400000) )) && echo "$f"
done | wc -l

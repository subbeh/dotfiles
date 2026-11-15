# vi: ft=gitconfig
# Test suites create throwaway repos under /tmp; signing their commits would queue on the YubiKey.
[commit]
	gpgsign = false

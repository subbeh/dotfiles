# YubiKey

One GPG key on four YubiKeys. Any card works for gpg, SSH and the Bitwarden
session.

- Key `0xD70DB41617DF61F1`: an offline Certify key `[C]` plus three rsa4096
  subkeys that expire 2028-07-09:
  - `0x3E253472A8068BCE` `[E]`
  - `0xC2E0A94E58A4DD06` `[S]`
  - `0x708929D425912FEF` `[A]`
- Every card holds the same three subkeys.
- The Certify key and subkey backup live in the Bitwarden item `gpg-yubikey`.
  Cards can't export keys, so that item is the only way to load another card.
- FIDO2 credentials can't be copied between cards. LUKS root and each 2FA site
  enroll every card separately.

Background on the GPG key and card setup:
[drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide).

## Switching cards

gpg's key stubs record a card's serial number. Inserting a card triggers
`90-yubikey-gpg.rules`, which starts `yubikey-gpg-relearn.service` to point the
stubs at that card. To do it by hand:

```bash
gpg-connect-agent "scd serialno" "learn --force" /bye
```

## Add a card

Insert only the new card. Every secret comes from the Bitwarden item
`gpg-yubikey`: attachments `D70DB41617DF61F1-{Certify,Subkeys}.key`, fields
`certify-pass`, `gpg-admin-pin`, `gpg-user-pin` and `fido2-pin`. The commands
below read them into shell variables without printing them.

```bash
bwf() { bw get item gpg-yubikey | jq -r --arg n "$1" '.fields[] | select(.name == $n).value'; }
bwa() { bw get attachment "D70DB41617DF61F1-$1.key" --itemid "$(bw get item gpg-yubikey | jq -r .id)" --raw; }
CERTIFY_PASS=$(bwf certify-pass) ADMIN_PIN=$(bwf gpg-admin-pin) USER_PIN=$(bwf gpg-user-pin)
```

### 1. PINs

Give the new card the same PINs as the others. Use ykman: gpg's
`--change-pin` menu needs a TTY. Run `ykman openpgp reset` first if the card
isn't factory-fresh.

```bash
gpgconf --kill scdaemon   # gpg's scdaemon holds the card and blocks ykman
ykman openpgp access change-admin-pin -a 12345678 -n "$ADMIN_PIN"
ykman openpgp access change-pin -P 123456 -n "$USER_PIN"
```

### 2. Load the subkeys

Work in a throwaway keyring on tmpfs. `keytocard` writes to the card right
away. The keyring change isn't saved, so the real keyring is never touched.

Select each subkey by key ID, not by index: here the index order is E, S, A.
The throwaway keyring needs `scdaemon.conf` (`disable-ccid`) to reach the card
through pcscd. Stop the real agent before each key, because shells that decrypt
the Bitwarden session restart it and it grabs the card ("No such device",
"Bad PIN").

```bash
REAL=$(gpgconf --list-dirs homedir)
export GNUPGHOME=$(mktemp -d -p "$XDG_RUNTIME_DIR")
cp "$REAL/scdaemon.conf" "$GNUPGHOME/"
bwa Subkeys | gpg --batch --import
for k in "0xC2E0A94E58A4DD06 1" "0x3E253472A8068BCE 2" "0x708929D425912FEF 3"; do  # [S] [E] [A] -> card slot
  set -- $k
  GNUPGHOME=$REAL gpgconf --kill scdaemon gpg-agent; sleep 1
  gpg --no-tty --command-fd 0 --pinentry-mode loopback --edit-key 0xD70DB41617DF61F1 <<EOF
key $1
keytocard
$2
$CERTIFY_PASS
$ADMIN_PIN
quit
n
EOF
done
gpgconf --kill all
rm -rf "$GNUPGHOME"; unset GNUPGHOME
gpg-connect-agent "scd serialno" "learn --force" /bye   # point the real stubs at this card
```

### 3. Verify GPG and SSH

```bash
gpg --card-status          # the three subkey fingerprints, no [none]
gpg -K                      # ssb> on all three
echo test | gpg --clearsign | gpg --verify                 # Good signature
echo ok | gpg -e -r 0xD70DB41617DF61F1 | gpg -d           # ok
ssh-add -L                  # shows the cardno: key
```

### 4. LUKS root

Add a FIDO2 slot next to the existing ones. The FIDO2 PIN is separate from the
OpenPGP PINs and is the one boot asks for. Enrolling first asks for the
passphrase or another enrolled card.

```bash
gpgconf --kill scdaemon
ykman fido access change-pin -n "$(bwf fido2-pin)"   # same FIDO2 PIN on every card
sudo systemd-cryptenroll /dev/disk/by-partlabel/root --fido2-device=auto
sudo cryptsetup luksDump /dev/disk/by-partlabel/root | grep -A2 systemd-fido2
```

Touch the card when it blinks after you enter the PIN. The touch hint prints
before the PIN prompt, but a touch missed after it fails with
`FIDO_ERR_OPERATION_DENIED` and enrolls nothing. There should be one
`systemd-fido2` token per card. Reboot with only the new card inserted to test
it.

### 5. 2FA

On each account that uses security keys, register the new card as an extra
key.

## Renew subkeys

Do this before 2028-07-09. Renewing only extends the expiry on the public key,
so the cards keep their keys.

```bash
export GNUPGHOME=$(mktemp -d -p "$XDG_RUNTIME_DIR")
bwa Certify | gpg --batch --import   # bwa from "Add a card"
gpg --pinentry-mode loopback --passphrase "$(bwf certify-pass)" --quick-set-expire FFAAC926BF6D09A02DB3345FD70DB41617DF61F1 2y '*'
gpg --armor --export 0xD70DB41617DF61F1 >"$XDG_RUNTIME_DIR/pub.asc"
rm -rf "$GNUPGHOME"; unset GNUPGHOME
gpg --import "$XDG_RUNTIME_DIR/pub.asc"
gpg --keyserver keys.openpgp.org --send-keys 0xD70DB41617DF61F1
```

Other machines pick the new expiry up with
`gpg --keyserver keys.openpgp.org --refresh-keys`.

Replacing the subkeys means loading the new ones onto all four cards (steps
2–3 for each card) and updating the Bitwarden backup.

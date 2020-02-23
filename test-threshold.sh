#!/bin/sh
# Generate some threshold key shards,
# Use each shard to partially sign a message
# Merge the partial signatures
# Use openssl to validate the signature

TMP=`mktemp -d`

die() { echo >&1 "$@" ; exit 1 ; }


./cosign threshold $TMP/key \
|| die "threshold key generation failed"

echo "The Magic Words are Squeamish Ossifrage $$" \
	> $TMP/file.txt

for i in 0 1 2; do
	./cosign sign $TMP/key-$i.key \
		< $TMP/file.txt \
		> $TMP/sig-$i \
	|| die "$i signature failed"
done


#
# Try all three good verifications
#
./cosign merge $TMP/key.pub \
	$TMP/sig-[01] \
	> $TMP/sig01 \
|| die "01 signature merge failed"

echo -n >&2 "01 correct signatures and key:    "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig01 \
	< $TMP/file.txt \
|| die "01 signature verification failed"


./cosign merge $TMP/key.pub \
	$TMP/sig-[12] \
	> $TMP/sig12 \
|| die "12 signature merge failed"

echo -n >&2 "12 correct signatures and key:    "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig12 \
	< $TMP/file.txt \
|| die "12 signature verification failed"


./cosign merge $TMP/key.pub \
	$TMP/sig-[02] \
	> $TMP/sig02 \
|| die "02 signature merge failed"

echo -n >&2 "02 correct signatures and key:    "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig02 \
	< $TMP/file.txt \
|| die "02 signature verification failed"


#
# Regenerate a new key from two of the shards
# and try a threshold signature
#
./cosign split $TMP/newkey $TMP/key-2.key $TMP/key-0.key \
|| die "key re-split failed"

./cosign sign $TMP/newkey-1.key \
	< $TMP/file.txt \
	> $TMP/newsig-1 \
|| die "1 signature failed"

./cosign sign $TMP/newkey-2.key \
	< $TMP/file.txt \
	> $TMP/newsig-2 \
|| die "2 signature failed"

./cosign merge $TMP/newkey.pub $TMP/newsig-[12] > $TMP/newsig \
|| die "re-split merge failed"

echo -n >&2 "re-split correct signatures and key:    "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/newsig \
	< $TMP/file.txt \
|| die "newsig signature verification failed"



#
# Try the wrong file
#
echo "Wrong file" > $TMP/wrong.txt
echo -n >&2 "wrong file should fail:        "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig01 \
	< $TMP/wrong.txt \
&& die "wrong file verification should have failed"


#
# Try with a missing partial signature
#
echo -n >&2 "missing signature should fail: "
./cosign merge $TMP/key.pub \
	$TMP/sig-1 \
	> $TMP/sig \
&& die "signature merge did not failed"


#
# Corrupt one partial signature
#
dd status=none if=/dev/urandom of=$TMP/sig-0 bs=256 count=1

echo -n >&2 "01 corrupt signature should fail: "
./cosign merge $TMP/key.pub \
	$TMP/sig-[02] \
	> $TMP/sig \
&& die "signature merge should have failed"


########
echo >&2 "ALL TESTS PASSED"
rm -rf $TMP

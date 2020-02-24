#!/bin/sh
# Generate some key shards,
# Use each shard to partially sign a message
# Merge the partial signatures
# Use openssl to validate the signature

. ./tests/test-functions.sh

$COSIGN genkey 4 $TMP/key \
|| die "key generation failed"

echo "The Magic Words are Squeamish Ossifrage $$" \
	> $TMP/file.txt

for i in 0 1 2 3; do
	$COSIGN sign $TMP/key-$i.key \
		< $TMP/file.txt \
		> $TMP/sig-$i \
	|| die "$i signature failed"
done


#
# Try a good verification
#
$COSIGN merge $TMP/key.pub \
	$TMP/sig-* \
	> $TMP/sig \
|| die "signature merge failed"

echo -n >&2 "correct signatures and key:    "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig \
	< $TMP/file.txt \
|| die "signature verification failed"


#
# Try the wrong public key
#
$COSIGN genkey 2 $TMP/key2 \
|| die "unable to generate second key?"

echo -n >&2 "wrong public key should fail:  "
openssl dgst \
	-verify $TMP/key2.pub \
	-signature $TMP/sig \
	< $TMP/file.txt \
&& die "wrong public key signature verification passed"


#
# Try the wrong file
#
echo "Wrong file" > $TMP/wrong.txt
echo -n >&2 "wrong file should fail:        "
openssl dgst \
	-verify $TMP/key.pub \
	-signature $TMP/sig \
	< $TMP/wrong.txt \
&& die "wrong file verification should have failed"


#
# Try with a missing partial signature
#
echo -n >&2 "missing signature should fail: "
$COSIGN merge $TMP/key.pub \
	$TMP/sig-[123] \
	> $TMP/sig \
&& die "signature merge did not failed"


#
# Corrupt one partial signature
#
dd status=none if=/dev/urandom of=$TMP/sig-0 bs=256 count=1

echo -n >&2 "corrupt signature should fail: "
$COSIGN merge $TMP/key.pub \
	$TMP/sig-* \
	> $TMP/sig \
&& die "signature merge should have failed"

#
# Try to generate a threshold key from non-threshold keys
#
echo -n >&2 "not threshold keys should fail: "
$COSIGN threshold $TMP/newkey $TMP/key-1.key $TMP/key-2.key \
&& die "threshold key should have died"


########
echo >&2 "ALL TESTS PASSED"
rm -rf $TMP

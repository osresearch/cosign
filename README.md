![Multiple overlapping cosines](logo.png)

# `cosign`: Cooperative RSA signatures

The `cosign` tool allows multiple cooperating parties to generate an RSA
key and split it between themselves, and then perform partial signatures
of a message that can be combined into a single valid RSA signatue of
that message, without any of the parties having a complete copy of the
private key after the initial generate stage.

The number of parties is unlimited, although this is not a threshold
signature scheme where only a subset are required -- with `cosign`
all the parties must perform their partial signature to be able to
generate a valid RSA signature.  It is also simplified in that the
initial key splitting stage requires a "trusted dealer" to perform
the split and hand the shards to the parties.

An example use for this is to interoperate with UEFI Secureboot, which
requires a single RSA signature on an executable to accept it.  For
high-assurance use cases, it is desirable that multiple parties must
reproducibly build the firmware image and individually sign the image
so that no single developer can subvert the security of the boot process.

**WARNING**
`cosign` is currently in the proof-of-concept stage.  The security
properties of the key sharding has not been reviewed for vulnerabilities
and the Python modular exponentiation function is not side-channel safe.

# Usage

The tool has three modes: key generation, partial signature generation,
and signature merging.

## Key generation and dealing

```
cosign genkey N basename
```

Produces N private key shares `basename-N.key` and public key
`basename.pub`.  The public key can be published and the inidividual key
shares should be sent to the cosigners under separate secured channels.

After generation the shares should never be brought together since the
private key can be regenerated from all of them together.


## Partial signature generation

```
cosign sign key-n.key < file > sig-n
```

Uses partial key to sign stdin and writes signature to stdout.
Each cosigning party must do this separately and send their partial
signatures to a coordinator to combine them.

This process must be done on a trusted machine to avoid leaking
the private key shard.  The cosigning parties can work in parallel
and do not need to communicate other than that they are all signing
the same message.


## Signature merging
```
cosign merge key.pub sig-* > file.sig
```

Merges the partial signature files into a full signature.  All of
the cosigning parties must sign the same file and send their partial
signatures to the coordinator to combine them.

This process requires no secret information (assuming the partial
signatures do not leak any key material), nor the contents of the message
itself, so it can be done by an untrusted machine or by any number of
machines in public to produce the valid RSA signature on the message.


## Verifying signature
```
openssl dgst -verify key.pub -signature file.sig < file
```

Verify the merged signature with the public key.  The value that
is actually signed is an PKCS#1-v1.5 encoded structure defined in
[RFC 3447 section 9.2](https://tools.ietf.org/html/rfc3447#section-9.2).


```
openssl rsautl -verify -pubin -inkey key.pub -asn1parse -in file
```

Produce an ASN1 tree of the signed file for debugging if
the verification fails for some reason.


# Limitations

`cosign` requires a trusted dealer to perform the key split.
The dealer can keep a copy of the whole private key or leak it
to one of the conspiring parties.

`cosign` requires all of the key holders to perform their partial
signature in order to produce a valid signature.  2-of-3 could be done
by producing multiple shards for each combination, but beyond that the
system would become unweildy.

The private key is recoverable if all of the shards are combined.
This might be a good thing if it is desirable to be able to re-shard
the key.  If the shards are stored in a hardware token, it might be
difficult to recover the shard in a format that would allow
recombination.

The security properties of the partial signatures is not known.
The random `d_i` values do not meet the coprime conditions, for instance.

Unfortunately the partial private keys are not compatible with hardware
tokens like Yubikeys since the key shards do not have the
[Chinese Remainder Theorem (CRT)](https://en.wikipedia.org/wiki/Chinese_remainder_theorem)
values, nor the primes `p` & `q` and the `dp` & `dq` values, that the
hardware tokens use to perform efficient RSA operations.


# Inspiration

This is inspired by an reply [posted to crypto.stackexchange.com](https://crypto.stackexchange.com/questions/67548/secure-multi-party-computation-for-digital-signature) by [@poncho](https://crypto.stackexchange.com/users/452/poncho)
as a "_fairly straight-forward method using RSA_":

> ## Key generation phase:
>
> The dealer selects a random RSA public/private keypair $(n,e,d)$
> 
> The dealer then selects $N$ values $d1,d2,…,dN$ with the constraint that $d1+d2+…+dN≡d(modλ(n))$
> 
> The dealer privately sends $d_i$ to party $i$, and publishes the public key $(n,e)$
>
> ## Signature generation phase:
>
> Each party gets a copy of the value to be signed $S$
> 
> Each party $i$ deterministically pads $S$ (perhaps using PKCS #1.5 signature padding,
> perhaps using PSS using randomness seeded by $S$), and then raises that to the power of $d_i mod n$;
> that is, it computes $sig_i=Pad(S)^{di} mod n$
> 
> Each party sends sigi to a collector, which computes $sig=sig1⋅sig2⋅…⋅s_n mod n$, and broadcasts it
> 
> Everyone checks if $sig$ is a valid signature to the value $s$; if not, then a malicious party is detected

There has been lots of other research into multiparty RSA going back to
Boyd ("Digital multisignatures" Cryptography and Coding, 1986).  Most of
the algorithm research has focused on threshold RSA and distributed
private key generation, although none of the literature seems to have
usable implementations.

There are some startups in this space as well, but they are not
using open source software nor publishing their algorithms, so they
are essentially both a trusted dealer and all of the trusted parties.

![Multiple overlapping cosines](logo.png)

![Multiple overlapping cosines](logo.png)

# `cosign`: Cooperative RSA signatures

The `cosign` tool allows multiple cooperating parties to generate an RSA key
and split it between themselves, and then perform partial signatures
of a message that can be combined into a single valid RSA signatue of
that message, without any of the parties having a complete copy of the
private key after the initial generate stage.

The number of parties is unlimited, although this is not a threshold
signature scheme where only a subset are required -- with `cosign`
all the parties must perform their partial signature to be able to
generate a valid RSA signature.  It is also simplified in that the
initial key splitting stage requires a "trusted dealer" to perform
the split and hand the shards to the parties.

An example use for this is to interopate with UEFI Secureboot, which
requires a single RSA signature on an executable to accept it.  For
high-assurance use cases, it is desirable that multiple parties must
reproducibly build the firmware image and individually sign the image
so that no single developer can subvert the security of the boot process.


# Usage

The tool has three modes: key generation, partial signature generation, and signature merging.

* `cosign genkey N basename`

Produces N private key shares `basename-N.key` and public key `basename.pub`

* `cosign sign key-n.key < file > sig-n`

Uses partial key N to sign data read from `stdin` and writes raw partial signature to `stdout`

* `cosign merge key.pub sig-* > file.sig`

Merges the partial signature files into a full signature.


# Limitations

Unfortunately the partial private keys are not compatible with hardware tokens like Yubikeys
since they do not have the Chinese Remainder Theorem (CRT) components that it uses to perform
efficient RSA operations.

`cosign` requires a trusted dealer to perform the key split.

`cosign` requires all of the key holders to perform their partial signature in order to
produce a valid signature.  2-of-3 could be done by producing multiple shards for each
combination, but beyond that the system would become unweildy.

The security of the partial signatures is not known.


# Inspiration

This is inspired by an idea from https://crypto.stackexchange.com/questions/67548/secure-multi-party-computation-for-digital-signature

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



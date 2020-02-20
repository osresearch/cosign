# Cooperative RSA signatures

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


# Usage

The tool has three modes: key generation, partial signature generation, and signature merging.

* `signtogether genkey N basename`

Produces N private key shares `basename-N.key` and public key `basename.pub`

* `signtogether sign key-n.key < file > sig-n`

Uses partial key N to sign data read from `stdin` and writes raw partial signature to `stdout`

* `signtogether merge key.pub sig-* > file.sig`

Merges the partial signature files into a full signature.


# Limitations

Unfortunately the partial private keys are not compatible with hardware tokens like Yubikeys
since they do not have the Chinese Remainder Theorem (CRT) components that it uses to perform
efficient RSA operations.



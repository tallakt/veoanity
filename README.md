# Veoanity

A simple script to generate either just regular private and public keys for
Amoveo, or generate vanity keys where the public key contains some wanted
characters.

Some notes about the vanity addresses:

- The first two characters of the public key dont use the complete base64
  alphabet.
- The wanted characters are searched within the complete public key string
- The characters "+" and "/" may be used to separate your word from the rest of
  the public key
- The process is slow: an hour perhaps for four letters matched
- The search may be case insensitive and will be a bit faster
- The script runs on up to 10 cores in parallell for speeding things up

Note: The author takes no responibility for the correctness of any generated
keys. You are suggested to test the keys with a small amount of veo before
committing to larger amounts.

## Running

Clone the repo from Github, and run the script with

```
$ elixir veoanity.exs
```

As generating keys is sensitive, you might want to read the script for yourself
to check that the keys are actually being generated at random. This is by
design.


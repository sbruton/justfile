# Shared [`just`] Methods for Rust Development

This crate contains a bunch of utility methods for automating rust development activities.

You can incorporate it into your project's local `justfile` by adding this hidden method.

```sh
# sync shared justfile
_sync:
    if [[ ! -d .cache ]]; then \
        mkdir .cache; \
    fi
    if [[ ! -f .last-sync ]]; then \
        echo "1970-01-01T00:00:00.000000Z" > .last-sync; \
    fi
    if [[ `gdate --date $(cat .last-sync) +%s || date --date $(cat .last-sync) +%s` -lt `echo $(date +%s) - 86400 | bc` ]]; then \
        if [[ -d .cache/.git ]]; then \
            cd .cache; \
            git pull; \
            cd -; \
        else \
            if [[ -d .cache ]]; then rm -rf .cache; fi; \
            mkdir .cache; \
            cd .cache; \
            git clone https://github.com/sbruton/justfile .; \
            cd -; \
        fi; \
    fi
```

and then you can simply add `_sync` as a pre-requisite to any just command that will use the shared functions

**Automate a build of all common OS targets**

```sh
build-all: _sync
  just -f .cache/justfile build-all `pwd`
```

See the [`justfile`] for all the available methods.

[`just`]: https://github.com/casey/just
[`justfile`]: justfile

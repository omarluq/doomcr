# doomcr

<video src="assets/vid.mp4" controls muted loop playsinline></video>

Run `doomgeneric` in a terminal using `termisu` (Crystal).

## Docker (recommended)

```bash
# Build image
docker build -t doomcr:latest .

# Run with shareware DOOM1.WAD (default source)
docker run --rm -it doomcr:latest

# Run with Freedoom instead
docker run --rm -it -e DOOM_WAD_SOURCE=freedoom doomcr:latest
```

Persist downloaded WAD files between runs:

```bash
docker run --rm -it -v "$(pwd)/wads:/data/wads" doomcr:latest
```

Use your own IWAD directly:

```bash
docker run --rm -it -v "/absolute/path/to:/iwads:ro" doomcr:latest -iwad /iwads/doom1.wad
```

Supported runtime flags:

- `DOOM_WAD_SOURCE=shareware|freedoom` (default: `shareware`)
- `DOOM_SHAREWARE_URL=<url>` to override the shareware download URL
- `DOOM_WAD=/path/in/container/file.wad` to bypass auto-download

## Native Library

`libdoomgeneric.a` is committed in the repo root and used directly by both local Crystal builds and Docker builds.

If you want to rebuild it:

```bash
git clone https://github.com/ozkl/doomgeneric vendor/doomgeneric
chmod +x docker/build_doomgeneric.sh
./docker/build_doomgeneric.sh
```

This regenerates `./libdoomgeneric.a`.

## Development

```bash
# Run tests
crystal spec

# Run task runner workflow (format + lint + spec)
bin/hace all

# Optional wrappers for docker commands
bin/hace docker:build
bin/hace docker:run
bin/hace docker:run:freedoom
```

Basic controls in this terminal port:

- Arrow keys: movement/turn
- `space` or `f`: fire
- `e`: use/open
- `esc`: menu
- `Ctrl+Q`: quit wrapper

## Contributing

1. Fork it (<https://github.com/omarluq/doomcr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [omarluq](https://github.com/omarluq) - creator and maintainer

## License Note

`doomgeneric` is GPL-2.0 licensed upstream. If you distribute builds containing it, review GPL obligations.

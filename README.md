# Lockbox Website #

## Building Locally ##

to build the GitHub-pages style locally, you can use the provided `Dockerfile` to create an image:

```bash
git clone https://github.com/mozilla-lockbox/mozilla-lockbox.github.io
cd mozilla-lockbox.github.io
docker build --tag mozilla-lockbox.github.io .
```

Then create and run a container to run a local Jekyll server:

```bash
cd mozilla-lockbox.github.io
docker run --rm --tty --interactive --publish 4000:4000 --volume $PWD:/srv/jekyll mozilla-lockbox.github.io
```

The documentation can be seen and tracked by opening a web browser to `http://localhost:4000/`.

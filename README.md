# Firefox Lockwise

[This][repo-link] is a meta-repository to gather documentation and project-wide
tasks for Mozilla's experimental [Lockwise product][org-link] (formerly known as Lockbox).

Please visit the [Lockwise website][website-link] for more information.

## Building Locally ##

To build the GitHub-pages style locally, you can use the provided `Dockerfile` to create an image:

```bash
git clone https://github.com/mozilla-lockwise/mozilla-lockwise.github.io
cd mozilla-lockwise.github.io
docker build --tag mozilla-lockwise.github.io .
```

Then create and run a container to run a local Jekyll server:

```bash
cd mozilla-lockwise.github.io
docker run --rm --tty --interactive --publish 4000:4000 --volume $PWD:/srv/jekyll mozilla-lockwise.github.io
```

The documentation can be seen and tracked by opening a web browser to `http://localhost:4000/`.

Learn more about how to [set up your GitHub Pages site locally](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/).

## Contributing ##

See the [guidelines][contributing-link] for contributing to this project.

This project is governed by a [Code Of Conduct][coc-link].

## [License][license-link]

This project is licensed under the [Mozilla Public License, version 2.0][license-link].

[repo-link]: https://github.com/mozilla-lockwise/mozilla-lockwise.github.io
[org-link]: https://github.com/mozilla-lockwise/
[website-link]: https://mozilla-lockwise.github.io/
[contributing-link]: /contributing.md
[coc-link]: /CODE_OF_CONDUCT.md
[license-link]: /LICENSE

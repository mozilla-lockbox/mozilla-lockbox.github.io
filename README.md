# Lockbox

[This][repo-link] is a meta-repository to gather documentation and project-wide
tasks for Mozilla's experimental [Lockbox product][org-link].

Please visit the [Lockbox website](website-link) for more information.

## Building Locally ##

To build the GitHub-pages style locally, you can use the provided `Dockerfile` to create an image:

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

Learn more about how to [set up your GitHub Pages site locally](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/).

## Contributing ##

See the [guidelines][contributing-link] for contributing to this project.

This project is governed by a [Code Of Conduct][coc-link].

## [License][license-link]

This project is licensed under the [Mozilla Public License, version 2.0][license-link].

[repo-link]: https://github.com/mozilla-lockbox/mozilla-lockbox.github.io
[org-link]: https://github.com/mozilla-lockbox/
[website-link]: https://mozilla-lockbox.github.io/
[contributing-link]: /contributing.md
[coc-link]: /code_of_conduct.md
[license-link]: /LICENSE

# Publishing Platform Dependabot Merger

This repository runs a daily GitHub action that automatically approves and merges certain Dependabot PRs for opted-in Publishing Platform repos.

Note that govuk-dependabot-merger will avoid merging a PR if it has a failing GitHub Action CI workflow called `CI`.

## Usage

To opt into the publishing-platform-dependabot-merger service, first create a `.publishing_platform_dependabot_merger.yml` config file at the root of your repository. Configure the file with an array of dependencies and associated semver bumps that you would like the service to merge for you.

For example:

```yaml
api_version: 2
defaults:
  update_external_dependencies: false # default: false
  auto_merge: true # default: true
  allowed_semver_bumps: # allowed values: `[patch, minor, major]`
    - patch
    - minor
  # The above sets the default policy for all dependencies in your project.
  # But each of the above properties can be overridden on a per-dependency basis below.
overrides:
  # Example of overriding `allowed_semver_bumps`:
  - dependency: rails
    allowed_semver_bumps:
      - patch # minor/major bumps should be upgraded manually.
  # Example of opting a specific dependency out of automatic patching:
  - dependency: publishing_platform_api_adapters
    auto_merge: false
  # Example of opting a specific dependency into automatic patching:
  - dependency: rspec
    update_external_dependencies: true
```

After you've merged your config file into your main branch, you just need to add your repository to the [config/repos_opted_in.yml](config/repos_opted_in.yml) list in publishing-platform-dependabot-merger.

## Technical documentation

### Running the test suite

To run the linter:

```
bundle exec rubocop
```

To run the tests:

```
bundle exec rspec
```

### Using the merger locally

The repo expects an `AUTO_MERGE_TOKEN` environment variable to be defined. This should be a GitHub API token with sufficient scope.

You can then run the merger with:

```
bundle exec ruby bin/merge_dependabot_prs.rb
```

If you want to do a dry run:

```
bundle exec ruby bin/merge_dependabot_prs.rb --dry-run
```

The repo also ships with a "doctor" script to help you to debug individual PRs and why they did or did not auto-merge.

```
bundle exec ruby bin/pr_doctor.rb https://github.com/publishing-platform/publishing-api/pull/125
```

## Licence

[MIT LICENSE](LICENSE).
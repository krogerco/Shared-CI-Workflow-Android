# Shared-CI-Workflow-Android

Shared workflows used by Kroger's GitHub actions.

- [Workflows](#workflows)
  - [Usage](#usage)
    - [Meta Workflow](#meta-workflow)
      - commit_lint
      - release
    - [Semantic Library Workflow](#semantic-library-workflow)
      - version determination
      - commit lint
      - ktlint
      - build
      - unit tests
      - instrumented tests
      - release on github (if criteria are met and all jobs succeed)
      - publish (if criteria are met and all jobs succeed)
  - [Secrets](#secrets)

## Workflows
These workflows are specific to our use case and rely heavily on the [Semantic Release](https://github.com/semantic-release/semantic-release) and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) tooling to automate our versioning. However, if you currently use or are starting a new project and use these tools you could use these workflows entirely as well.
Click the link header of a workflow to view its conifguration file including available inputs and default values.

## Usage
#### [Meta Workflow](/.github/workflows/semantic_library_workflow.yml)
Workflow to handle automatic versioning of this repository and the [actions](https://github.com/krogerco/Shared-CI-Action-Android) repository.
```yml
name: Actions Release

on: push

jobs:
  meta_workflow:
    name: push
    uses: krogerco/Shared-CI-Workflow-Android/.github/workflows/meta_workflow.yml@<latest-version>
```

#### [Semantic Library Workflow](/.github/workflows/semantic_library_workflow.yml)
```yml
name: Commit

on:
  push:

jobs:
  semantic_library_workflow:
    name: push
    uses: krogerco/Shared-CI-Workflow-Android/.github/workflows/semantic_library_workflow.yml@<latest-version>
    secrets:
      ORG_GRADLE_PROJECT_mavenCentralUsername: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}
      ORG_GRADLE_PROJECT_mavenCentralPassword: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralPassword }}
      ORG_GRADLE_PROJECT_signingInMemoryKey: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKey }}
      ORG_GRADLE_PROJECT_signingInMemoryKeyId: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyId }}
      ORG_GRADLE_PROJECT_signingInMemoryKeyPassword: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyPassword }}
      REPO_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Secrets
- REPO_ACCESS_TOKEN:
  - Available by default
  - Accessed as `${{ secrets.GITHUB_TOKEN }}`

### Publishing Secrets
All publishing secrets should be set in your repository secret settings when the [semantic library workflow](#semantic-library-workflow) is used.

- ORG_GRADLE_PROJECT_mavenCentralUsername:
  - Username for Maven Central
- ORG_GRADLE_PROJECT_mavenCentralPassword:
  - Password for Maven Central
- ORG_GRADLE_PROJECT_signingInMemoryKey:
  - The private GPG key.
- ORG_GRADLE_PROJECT_signingInMemoryKeyId:
  - The public key ID.
- ORG_GRADLE_PROJECT_signingInMemoryKeyPassword:
  - The GPG passphrase (if created with one)

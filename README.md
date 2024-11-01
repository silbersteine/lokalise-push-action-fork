# GitHub action to push changed translation files from Lokalise

GitHub action to upload changed translation files in the base language from your GitHub repository to [Lokalise TMS](https://lokalise.com/).

**Step-by-step tutorial covering the usage of this action is available on [Lokalise Developer Hub](https://developers.lokalise.com/docs/github-actions).** To download translation files from Lokalise to GitHub, use the [lokalise-pull-action](https://github.com/lokalise/lokalise-pull-action).

## Usage

Use this action in the following way:

```yaml
name: Demo push with tags
on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Push to Lokalise
        uses: lokalise/lokalise-push-action@v1.0.0
        with:
          api_token: ${{ secrets.LOKALISE_API_TOKEN }}
          project_id: LOKALISE_PROJECT_ID
          base_lang: BASE_LANG_ISO
          translations_path: |
            TRANSLATIONS_PATH1
            TRANSLATIONS_PATH2
          file_format: FILE_FORMAT
          additional_params: ADDITIONAL_CLI_PARAMS
```

## Configuration

### Parameters

You'll need to provide some parameters for the action. These can be set as environment variables, secrets, or passed directly. Refer to the [General setup](https://developers.lokalise.com/docs/github-actions#general-setup-overview) section for detailed instructions.

The following parameters are **mandatory**:

- `api_token` — Lokalise API token.
- `project_id` — Your Lokalise project ID.
- `translations_path` — One or more paths to your translations. For example, if your translations are stored in the `locales` folder at the project root, use `locales` (leave out leading and trailing slashes).
- `file_format` — Translation file format. For example, if you're using JSON files, just put `json` (no leading dot needed).
- `base_lang` — The base language of your project (e.g., `en` for English).

**Optional** parameters include:

- `additional_params` — Extra parameters to pass to the [Lokalise CLI when pushing files](https://github.com/lokalise/lokalise-cli-2-go/blob/main/docs/lokalise2_file_upload.md). For example, you can use `--convert-placeholders` to handle placeholders. You can include multiple CLI arguments as needed.
* `max_retries` — Maximum number of retries on rate limit errors (HTTP 429). The default value is `3`.
* `sleep_on_retry` — Number of seconds to sleep before retrying on rate limit errors. The default value is `1`.

## Technical details

### How this action works

When triggered, this action performs the following steps:

1. Detects all changed translation files since the previous commit for the base language in the specified format under the `translations_path`.
2. Uploads modified translation files to the specified project in parallel, handling up to six requests simultaneously.
3. Each translation key is tagged with the name of the branch that triggered the workflow.

If no changes have been detected in step 1, the following logic applies:

1. The action checks if this is the first run on the triggering branch. To achieve that, it searches for a `lokalise-upload-complete` tag.
   - If this tag is found, it means that the initial push has already been completed. The action will then exit.
2. If the tag is not found, the action will perform an initial push to Lokalise by uploading all translation files for the base language.
3. The action creates a `lokalise-upload-complete` tag, indicating that the initial setup has been successfully completed.
   - It is recommended to pull changes from the triggering branch to your local repo to include this tag into your local history.

For more information on assumptions, refer to the [Assumptions and defaults](https://developers.lokalise.com/docs/github-actions#assumptions-and-defaults) section.

### Default parameters for the push action

By default, the following command-line parameters are set when uploading files to Lokalise:

- `--token` — Derived from the `api_token` parameter.
- `--project-id` — Derived from the `project_id` parameter.
- `--file` — The currently uploaded file.
- `--lang-iso` — The language ISO code of the translation file.
- `--replace-modified`
- `--include-path`
- `--distinguish-by-file`
- `--poll`
- `--poll-timeout` — Set to `120s`.
- `--tag-inserted-keys`
- `--tag-skipped-keys=true`
- `--tag-updated-keys`
- `--tags` — Set to the branch name that triggered the workflow.

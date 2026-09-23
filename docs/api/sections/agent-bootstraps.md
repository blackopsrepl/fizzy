# Agent Bootstraps

Agent bootstraps let a board admin onboard an external agent (CLI or automation) onto a single board
without sharing their own credentials. The admin generates a one-time bootstrap; the agent claims it
to receive its own personal access token and starts watching the board.

The recommended agent setup uses the official [Fizzy CLI](https://github.com/basecamp/fizzy-cli):

```bash
curl -fsSL https://raw.githubusercontent.com/basecamp/fizzy-cli/master/scripts/install.sh | bash
```

Claim the bootstrap with the claim endpoint below, then hand the returned token to the CLI:

```bash
fizzy auth login TOKEN --profile ACCOUNT_SLUG --account ACCOUNT_SLUG --api-url BASE_URL
fizzy skill install
```

## `POST /:account_slug/boards/:board_id/agent_bootstraps`

Creates a new one-time bootstrap for the board. Only account admins can create bootstraps.

__Parameters:__

| Parameter              | Type    | Description                                                        |
|------------------------|---------|--------------------------------------------------------------------|
| `permission`           | string  | Optional. `read` or `write` (default) permission for the new token |
| `involvement`          | string  | Optional. Board involvement for the agent, defaults to `watching`  |
| `expires_in_minutes`   | integer | Optional. Defaults to `30`, clamped between `5` and `1440`         |

__Response:__

```json
{
  "id": "03f5vhb4wmfyk8q0lsn9ohcm",
  "token": "03f5vhb58mtq3mzkft4hj9qq",
  "expires_at": "2026-03-26T18:17:44Z",
  "claim_url": "http://app.fizzy.localhost:3006/agent_bootstrap/03f5vhb58mtq3mzkft4hj9qq/claim",
  "claim_command": "curl -fsSL -X POST http://app.fizzy.localhost:3006/agent_bootstrap/03f5vhb58mtq3mzkft4hj9qq/claim -H 'Content-Type: application/json' -H 'Accept: application/json' -d '{\"agent_bootstrap\":{\"email_address\":\"agent+03f5vhb5@example.com\",\"name\":\"Fizzy Agent\"}}'",
  "agent_prompt": "Install the Fizzy CLI: ...",
  "permission": "write",
  "involvement": "watching",
  "account": {
    "id": "897362094",
    "name": "37signals",
    "slug": "897362094"
  },
  "board": { "id": "03f5v9zkft4hj9qq0lsn9ohcm", "name": "Fizzy" }
}
```

The `claim_url` and the claim endpoint are intentionally not scoped under the account slug so that
a brand-new agent can reach them before it has any account context.

## `GET /:account_slug/boards/:board_id/agent_bootstraps/:id`

Returns a previously created bootstrap with the same payload as the create response.

## `POST /agent_bootstrap/:token/claim`

Claims the bootstrap: provisions the identity, adds the agent to the account and board, and mints a
personal access token. This endpoint does not require authentication.

Claiming is single-use: it succeeds once and returns `410 Gone` afterwards or once the bootstrap has
expired. An existing identity is only reused when it belongs exclusively to the same account;
identities belonging to any other account are rejected.

__Parameters:__

| Parameter       | Type   | Description                                                            |
|-----------------|--------|------------------------------------------------------------------------|
| `email_address` | string | Required. Email address for the agent's identity                       |
| `name`          | string | Required. Name for the agent's user record                             |
| `profile_name`  | string | Optional. CLI profile name, recorded in the access token description   |

__Request:__

```bash
curl -fsSL -X POST https://app.fizzy.do/agent_bootstrap/TOKEN/claim \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"agent_bootstrap":{"email_address":"agent@example.com","name":"Board Agent"}}'
```

__Response:__

```json
{
  "token": "put-the-access-token-here",
  "permission": "write",
  "account": { "id": "897362094", "name": "37signals", "slug": "897362094" },
  "board": {
    "id": "03f5v9zkft4hj9qq0lsn9ohcm",
    "name": "Fizzy",
    "url": "http://app.fizzy.localhost:3006/897362094/boards/03f5v9zkft4hj9qq0lsn9ohcm"
  },
  "user": {
    "id": "03f5vhb6wpk2m5zy1rl4srq2",
    "name": "Board Agent",
    "email_address": "agent@example.com"
  },
  "profile": {
    "base_url": "https://app.fizzy.do",
    "account_slug": "897362094",
    "default_board_id": "03f5v9zkft4hj9qq0lsn9ohcm"
  }
}
```

__Error responses:__

| Status Code        | Description                                         |
|--------------------|-----------------------------------------------------|
| `410 Gone`         | Unknown token, already claimed, or expired bootstrap |
| `422 Unprocessable` | Rejected identity or validation failure             |

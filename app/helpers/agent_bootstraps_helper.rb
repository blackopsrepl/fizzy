module AgentBootstrapsHelper
  require "shellwords"

  FIZZY_CLI_INSTALL_COMMAND = "curl -fsSL https://raw.githubusercontent.com/basecamp/fizzy-cli/master/scripts/install.sh | bash"

  def link_to_agent_bootstrap(board)
    link_to new_board_agent_bootstrap_path(board),
        class: "btn btn--circle-mobile",
        data: { controller: "tooltip", bridge__overflow_menu_target: "item", bridge_title: "Agent setup" } do
      icon_tag("settings") + tag.span("Agent setup", class: "for-screen-reader")
    end
  end

  def agent_bootstrap_claim_url_for(agent_bootstrap)
    agent_bootstrap_claim_url(token: agent_bootstrap.token, script_name: nil)
  end

  def agent_bootstrap_claim_command(agent_bootstrap)
    payload = { agent_bootstrap: { email_address: agent_bootstrap_suggested_email(agent_bootstrap), name: agent_bootstrap_suggested_name(agent_bootstrap) } }.to_json

    Shellwords.shelljoin([
      "curl", "-fsSL", "-X", "POST", agent_bootstrap_claim_url_for(agent_bootstrap),
      "-H", "Content-Type: application/json",
      "-H", "Accept: application/json",
      "-d", payload
    ])
  end

  def agent_bootstrap_agent_prompt(agent_bootstrap)
    <<~TEXT.strip
      Install the Fizzy CLI:
      #{FIZZY_CLI_INSTALL_COMMAND}

      Claim this one-time bootstrap; the JSON response carries the access token, account slug, base URL, and board ID:
      #{agent_bootstrap_claim_command(agent_bootstrap)}

      Configure the CLI with those values:
      fizzy auth login TOKEN --profile ACCOUNT_SLUG --account ACCOUNT_SLUG --api-url BASE_URL
      export FIZZY_BOARD=BOARD_ID

      Verify access and load the Fizzy skill:
      fizzy auth status
      fizzy skill install
    TEXT
  end

  private
    def agent_bootstrap_suggested_email(agent_bootstrap)
      "agent+#{agent_bootstrap.token.to_s[0, 8]}@example.com"
    end

    def agent_bootstrap_suggested_name(agent_bootstrap)
      "#{agent_bootstrap.board.name} Agent"
    end
end

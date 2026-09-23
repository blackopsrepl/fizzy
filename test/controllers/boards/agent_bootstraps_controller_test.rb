require "test_helper"
require "shellwords"

class Boards::AgentBootstrapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "new" do
    get new_board_agent_bootstrap_path(boards(:writebook))
    assert_response :success
    assert_in_body "Generate setup command"
  end

  test "create as JSON" do
    board = boards(:writebook)

    assert_difference -> { board.agent_bootstraps.count }, +1 do
      post board_agent_bootstraps_path(board), as: :json
    end

    assert_response :created
    body = @response.parsed_body
    assert body["claim_url"].present?
    assert body["claim_command"].present?
    assert body["agent_prompt"].present?
    assert_match %r{/agent_bootstrap/[^/]+/claim\z}, body["claim_url"]
    assert_not_includes body["claim_url"], "/#{board.account.slug}/"
    assert_includes body["agent_prompt"], body["claim_url"]
    assert_includes body["agent_prompt"], body["claim_command"]
    assert_includes body["agent_prompt"], "fizzy auth login"
    assert_includes body["agent_prompt"], "fizzy skill install"
    assert_equal "watching", body["involvement"]
    assert_equal board.id, body.dig("board", "id")
  end

  test "claim command shell-escapes board-derived arguments" do
    board = boards(:writebook)
    board.update!(name: %(Danger "$(touch /tmp/nope)" `rm -rf /`))

    post board_agent_bootstraps_path(board), as: :json

    assert_response :created
    command = @response.parsed_body.fetch("claim_command")
    argv = Shellwords.split(command)

    assert_equal "curl", argv[0]
    payload = JSON.parse(argv[argv.index("-d") + 1])

    assert_match(/\Aagent\+[A-Za-z0-9]{8}@example\.com\z/, payload.dig("agent_bootstrap", "email_address"))
    assert_equal "#{board.name} Agent", payload.dig("agent_bootstrap", "name")
  end

  test "new requires account admin" do
    logout_and_sign_in_as :jz

    get new_board_agent_bootstrap_path(boards(:writebook))

    assert_response :forbidden
  end

  test "show" do
    bootstrap = boards(:writebook).agent_bootstraps.create!(
      account: accounts("37s"),
      creator: users(:kevin),
      expires_at: 30.minutes.from_now
    )

    get board_agent_bootstrap_path(bootstrap.board, bootstrap)
    assert_response :success
    assert_in_body bootstrap.token
    assert_in_body "Copy claim URL"
    assert_in_body "Copy agent prompt"
    assert_in_body "fizzy auth login"
  end

  test "show requires account admin" do
    bootstrap = boards(:writebook).agent_bootstraps.create!(
      account: accounts("37s"),
      creator: users(:kevin),
      expires_at: 30.minutes.from_now
    )

    logout_and_sign_in_as :jz
    get board_agent_bootstrap_path(bootstrap.board, bootstrap)

    assert_response :forbidden
  end

  test "board page includes agent setup link for account admins" do
    get board_path(boards(:writebook))
    assert_response :success
    assert_select "a[href='#{new_board_agent_bootstrap_path(boards(:writebook))}']"
  end

  test "board creator who is not an account admin cannot see bootstrap link" do
    logout_and_sign_in_as :jz
    board = Current.set(account: accounts("37s"), user: users(:jz)) do
      Board.create!(name: "Creator board", creator: users(:jz), all_access: false)
    end

    get board_path(board)

    assert_response :success
    assert_select "a[href='#{new_board_agent_bootstrap_path(board)}']", count: 0
  end

  test "board creator who is not an account admin cannot create bootstrap" do
    logout_and_sign_in_as :jz
    board = Current.set(account: accounts("37s"), user: users(:jz)) do
      Board.create!(name: "Creator board", creator: users(:jz), all_access: false)
    end

    assert users(:jz).can_administer_board?(board)

    assert_no_difference -> { board.agent_bootstraps.count } do
      post board_agent_bootstraps_path(board), as: :json
    end

    assert_response :forbidden
  end

  test "non-admin cannot create bootstrap for board they do not administer" do
    logout_and_sign_in_as :jz

    assert_no_difference -> { boards(:writebook).agent_bootstraps.count } do
      post board_agent_bootstraps_path(boards(:writebook)), as: :json
    end

    assert_response :forbidden
  end
end

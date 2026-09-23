json.id @agent_bootstrap.id
json.token @agent_bootstrap.token
json.expires_at @agent_bootstrap.expires_at.utc.iso8601
json.claim_url agent_bootstrap_claim_url_for(@agent_bootstrap)
json.claim_command agent_bootstrap_claim_command(@agent_bootstrap)
json.agent_prompt agent_bootstrap_agent_prompt(@agent_bootstrap)
json.permission @agent_bootstrap.permission
json.involvement @agent_bootstrap.involvement

json.account do
  json.(@agent_bootstrap.account, :id, :name, :slug)
end

json.board @agent_bootstrap.board, partial: "boards/board", as: :board

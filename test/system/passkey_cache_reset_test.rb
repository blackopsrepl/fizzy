require "application_system_test_case"

class PasskeyCacheResetTest < ApplicationSystemTestCase
  test "sign in button state resets before Turbo caches the page" do
    visit new_session_path
    assert_selector "rails-passkey-sign-in-button"

    execute_script <<~JS
      const component = document.querySelector("rails-passkey-sign-in-button")
      const button = component.querySelector("[data-passkey]")
      const error = component.querySelector('[data-passkey-error="error"]')

      button.disabled = true
      error.hidden = false

      document.dispatchEvent(new Event("turbo:before-cache"))
    JS

    assert_equal false, evaluate_script("document.querySelector('rails-passkey-sign-in-button [data-passkey]').disabled")
    assert_equal true, evaluate_script("document.querySelector('rails-passkey-sign-in-button [data-passkey-error=\"error\"]').hidden")
  end
end

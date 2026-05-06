# frozen_string_literal: true

require_relative "test_helper"

class ConfigTest < Minitest::Test
  include TrexbarSwayTestHelpers

  def test_default_config_is_valid
    with_temp_home do
      config = TrexbarSway::Core::Config.default_config
      assert_empty TrexbarSway::Core::Config.validate_config(config)
    end
  end

  def test_init_writes_config
    with_temp_home do |home|
      path = File.join(home, ".config", "trexbar-sway", "config.json")
      config = TrexbarSway::Core::Config.init_config(path)

      assert File.file?(path)
      assert_equal 11, config.dig(:runtime, :waybarSignal)
      assert_equal config, TrexbarSway::Core::Config.load_config(path)
    end
  end

  def test_invalid_interval_is_reported
    config = TrexbarSway::Core::Config.normalize_config(runtime: { refreshSeconds: 0 })
    issues = TrexbarSway::Core::Config.validate_config(config)

    assert issues.any? { |issue| issue[:field] == "runtime.refreshSeconds" }
  end
end

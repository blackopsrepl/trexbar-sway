# frozen_string_literal: true

require "json"

module TrexbarSway
  module CLI
    module_function

    def run(argv = ARGV)
      command = argv.first&.start_with?("-") ? "help" : (argv.shift || "help")
      args = parse_args(argv)
      config_path = args[:config] || Core::Config.default_config_path

      case command
      when "config"
        run_config_command(args, config_path)
      when "daemon"
        Runtime::Daemon.run(config_path, once: args[:once])
        0
      when "help"
        puts usage
        0
      when "panel"
        Runtime::QuickShell.open(config_path)
        0
      when "refresh"
        snapshot = Runtime::Daemon.refresh(config_path)
        print_json_if_requested(snapshot, args)
        0
      when "snapshot"
        snapshot = Runtime::Daemon.refresh(config_path)
        print_json(snapshot, args)
        0
      when "ui"
        run_ui_command(args, config_path)
      when "waybar"
        run_waybar_command(args, config_path)
      else
        raise ArgumentError, "Unknown command: #{command}"
      end
    rescue StandardError => e
      warn e.message
      1
    end

    def parse_args(argv)
      args = { format: "text", once: false, pretty: false, positionals: [] }
      index = 0

      while index < argv.length
        value = argv[index]
        case value
        when "--config"
          index += 1
          args[:config] = argv[index]
        when "--format"
          index += 1
          args[:format] = argv[index] == "json" ? "json" : "text"
        when "--pretty"
          args[:pretty] = true
        when "--once"
          args[:once] = true
        else
          args[:positionals] << value
        end
        index += 1
      end

      args
    end

    def run_config_command(args, config_path)
      subcommand = args[:positionals].first || "validate"
      if subcommand == "init"
        print_json(Core::Config.init_config(config_path), args)
        return 0
      end

      config = Core::Config.load_config(config_path)
      issues = Core::Config.validate_config(config)
      if args[:format] == "json"
        print_json(issues, args)
      elsif issues.empty?
        puts "Config valid."
      else
        issues.each { |issue| puts "#{issue[:severity].upcase}: #{issue[:field]} #{issue[:message]}" }
      end
      issues.any? { |issue| issue[:severity] == "error" } ? 1 : 0
    end

    def run_ui_command(args, config_path)
      subcommand = args[:positionals].first || "open"
      payload = case subcommand
                when "open"
                  Runtime::QuickShell.open(config_path)
                  Runtime::QuickShell.status(config_path)
                when "close"
                  Runtime::QuickShell.close(config_path)
                  Runtime::QuickShell.status(config_path)
                when "toggle"
                  Runtime::QuickShell.toggle(config_path)
                when "status"
                  Runtime::QuickShell.status(config_path)
                else
                  raise ArgumentError, "Unknown ui subcommand: #{subcommand}"
                end
      print_json_if_requested(payload, args)
      0
    end

    def run_waybar_command(args, config_path)
      subcommand = args[:positionals].first || "render"
      case subcommand
      when "render"
        Runtime::Waybar.render(config_path)
      when "refresh"
        Runtime::Waybar.refresh(config_path)
      when "panel", "open"
        Runtime::Waybar.open_panel(config_path)
      else
        raise ArgumentError, "Unknown waybar subcommand: #{subcommand}"
      end
      0
    end

    def print_json_if_requested(payload, args)
      print_json(payload, args) if args[:format] == "json"
    end

    def print_json(payload, args)
      puts(args[:pretty] ? JSON.pretty_generate(payload) : JSON.generate(payload))
    end

    def usage
      <<~TEXT
        trexbar-sway commands:
          config init|validate
          snapshot
          refresh
          daemon [--once]
          panel
          ui open|close|toggle|status
          waybar render|refresh|panel
      TEXT
    end
  end
end

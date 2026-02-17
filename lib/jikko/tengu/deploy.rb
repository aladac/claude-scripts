# frozen_string_literal: true

require "json"
require "fileutils"

module Jikko
  module Tengu
    class Deploy < Command
      # Host configurations - extensible for future hosts
      HOSTS = {
        "junkpile" => {
          ssh: "chi@junkpile",
          arch: "amd64",
          build: :remote, # Build on the target (native)
          description: "Local development server (AMD64)"
        }
        # Future:
        # "tengu" => {
        #   ssh: "chi@ssh.tengu.to",
        #   arch: "arm64",
        #   build: :local,  # Cross-compile locally with zigbuild
        #   description: "Hetzner Cloud server (ARM64)"
        # }
      }.freeze

      DEFAULT_HOST = "junkpile"
      PROJECT_PATH = File.expand_path("~/Projects/tengu")
      REMOTE_BUILD_PATH = "/tmp/tengu-build"

      def run
        parse_args

        @host = HOSTS[@host_key]
        unless @host
          err "Unknown host: #{@host_key}"
          err "Available hosts: #{HOSTS.keys.join(', ')}"
          return
        end

        unless Dir.exist?(PROJECT_PATH)
          err "Project not found: #{PROJECT_PATH}"
          return
        end

        title "Tengu Deploy: #{@host_key}"
        info @host[:description]

        unless preflight_checks
          err "Preflight checks failed"
          return
        end

        show_version_info

        unless @skip_confirm || confirm?("Deploy to #{@host_key}?")
          info "Deployment cancelled"
          return
        end

        success = case @host[:build]
                  when :remote
                    deploy_remote_build
                  when :local
                    deploy_local_build
                  else
                    err "Unknown build strategy: #{@host[:build]}"
                    false
                  end

        if success
          verify_deployment
          puts
          ok "Deployment complete!"
        else
          err "Deployment failed"
        end
      end

      private

      def parse_args
        @host_key = DEFAULT_HOST
        @skip_confirm = false
        @restart_only = false

        args.each_with_index do |arg, i|
          case arg
          when "-H", "--host"
            @host_key = args[i + 1] if args[i + 1]
          when "-y", "--yes"
            @skip_confirm = true
          when "-r", "--restart"
            @restart_only = true
          end
        end
      end

      def preflight_checks
        frame("Preflight Checks", color: :cyan) do
          # Check SSH connectivity
          ssh_ok = spin("SSH connectivity") do
            system("ssh -o ConnectTimeout=5 -o BatchMode=yes #{@host[:ssh]} 'echo ok' >/dev/null 2>&1")
          end
          unless ssh_ok
            err "Cannot connect to #{@host[:ssh]}"
            return false
          end
          ok "SSH: #{@host[:ssh]}"

          # Check git status
          Dir.chdir(PROJECT_PATH) do
            status = `git status --porcelain 2>/dev/null`.strip
            if status.empty?
              ok "Git: clean working tree"
            else
              warn "Git: uncommitted changes detected"
              muted status.lines.first(5).join
              muted "..." if status.lines.size > 5
            end
          end

          # Check required tools
          if @host[:build] == :local
            zigbuild_ok = system("which cargo-zigbuild >/dev/null 2>&1")
            unless zigbuild_ok
              err "cargo-zigbuild not found (required for cross-compilation)"
              return false
            end
            ok "cargo-zigbuild: installed"
          end

          true
        end
      end

      def show_version_info
        frame("Version Info", color: :cyan) do
          Dir.chdir(PROJECT_PATH) do
            @version = `grep '^version' Cargo.toml | head -1 | sed 's/.*"\\(.*\\)".*/\\1/'`.strip
            @commit = `git rev-parse --short HEAD 2>/dev/null`.strip
            @branch = `git branch --show-current 2>/dev/null`.strip

            info "Version: #{@version}"
            info "Commit:  #{@commit}"
            info "Branch:  #{@branch}"

            # Get current deployed version
            deployed = run_ssh("tengu --version 2>/dev/null || echo 'not installed'").strip
            info "Deployed: #{deployed}"
          end
        end
      end

      def deploy_remote_build
        return restart_service if @restart_only

        frame("Syncing Source", color: :green) do
          Dir.chdir(PROJECT_PATH) do
            # Write git hash for build
            File.write(".git_hash", @commit)

            spin("Syncing to #{@host_key}") do
              sh "rsync -az --delete " \
                 "--exclude 'target' " \
                 "--exclude '.git' " \
                 "--exclude '*.deb' " \
                 ". #{@host[:ssh]}:#{REMOTE_BUILD_PATH}/", capture: true
            end

            File.delete(".git_hash") if File.exist?(".git_hash")
          end
          ok "Source synced to #{REMOTE_BUILD_PATH}"
        end

        frame("Building on #{@host_key}", color: :green) do
          cargo_env = "source ~/.cargo/env"

          build_ok = spin("cargo build --release") do
            system("ssh #{@host[:ssh]} '#{cargo_env} && cd #{REMOTE_BUILD_PATH} && cargo build --release' >/dev/null 2>&1")
          end
          return false unless build_ok
          ok "Build complete"

          deb_ok = spin("cargo deb") do
            system("ssh #{@host[:ssh]} '#{cargo_env} && cd #{REMOTE_BUILD_PATH} && cargo deb --no-build' >/dev/null 2>&1")
          end
          return false unless deb_ok

          # Find the built deb
          @deb_path = run_ssh("ls -t #{REMOTE_BUILD_PATH}/target/debian/tengu_*.deb | head -1").strip
          ok "Package: #{File.basename(@deb_path)}"
        end

        install_and_restart(:remote)
      end

      def deploy_local_build
        return restart_service if @restart_only

        target = "aarch64-unknown-linux-gnu"

        frame("Building Locally", color: :green) do
          Dir.chdir(PROJECT_PATH) do
            build_ok = spin("cargo zigbuild --release --target #{target}") do
              sh "cargo zigbuild --release --target #{target}", capture: true
            end
            return false unless build_ok
            ok "Build complete"

            deb_ok = spin("cargo deb") do
              sh "cargo deb --no-build --no-strip --target #{target}", capture: true
            end
            return false unless deb_ok

            @deb_path = Dir.glob("target/debian/tengu_*_arm64.deb").max_by { |f| File.mtime(f) }
            ok "Package: #{File.basename(@deb_path)}"
          end
        end

        frame("Uploading to #{@host_key}", color: :green) do
          remote_deb = "/tmp/#{File.basename(@deb_path)}"

          upload_ok = spin("Uploading package") do
            system("scp #{@deb_path} #{@host[:ssh]}:#{remote_deb} >/dev/null 2>&1")
          end
          return false unless upload_ok

          @deb_path = remote_deb
          ok "Uploaded to #{remote_deb}"
        end

        install_and_restart(:local)
      end

      def install_and_restart(build_type)
        frame("Installing", color: :green) do
          # Stop service first
          spin("Stopping tengu service") do
            run_ssh("sudo systemctl stop tengu 2>/dev/null || true")
            true
          end

          # Install the deb
          install_ok = spin("Installing package") do
            result = run_ssh("sudo dpkg -i #{@deb_path} 2>&1")
            $?.success?
          end

          unless install_ok
            err "Package installation failed"
            # Try to show error
            output = run_ssh("sudo dpkg -i #{@deb_path} 2>&1")
            muted output
            return false
          end
          ok "Package installed"

          # Start service
          start_ok = spin("Starting tengu service") do
            run_ssh("sudo systemctl start tengu")
            sleep 2 # Give it time to start
            status = run_ssh("systemctl is-active tengu 2>/dev/null").strip
            status == "active"
          end

          unless start_ok
            err "Service failed to start"
            # Show logs
            logs = run_ssh("sudo journalctl -u tengu -n 20 --no-pager 2>/dev/null")
            muted logs
            return false
          end
          ok "Service started"
        end

        true
      end

      def restart_service
        frame("Restarting Service", color: :green) do
          spin("Restarting tengu") do
            run_ssh("sudo systemctl restart tengu")
            sleep 2
            status = run_ssh("systemctl is-active tengu 2>/dev/null").strip
            status == "active"
          end
          ok "Service restarted"
        end
        true
      end

      def verify_deployment
        frame("Verification", color: :cyan) do
          # Check version
          deployed = run_ssh("tengu --version 2>/dev/null").strip
          info "Deployed version: #{deployed}"

          # Check health
          sleep 1
          health = run_ssh("curl -s --connect-timeout 5 http://localhost:8080/health 2>/dev/null")
          begin
            status = JSON.parse(health)["status"]
            if status == "ok"
              ok "API health: ok"
            else
              warn "API health: #{status}"
            end
          rescue JSON::ParserError
            warn "API not responding yet (may still be starting)"
          end

          # Check service status
          uptime = run_ssh("systemctl show tengu --property=ActiveEnterTimestamp --value 2>/dev/null").strip
          info "Started: #{uptime}" unless uptime.empty?
        end
      end

      def run_ssh(cmd)
        `ssh -o ConnectTimeout=5 -o BatchMode=yes #{@host[:ssh]} '#{cmd}' 2>/dev/null`
      end
    end
  end
end

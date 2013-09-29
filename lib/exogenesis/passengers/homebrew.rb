require 'exogenesis/support/passenger'

# Manages Homebrew - the premier package manager for Mac OS
class Homebrew < Passenger
  INSTALL_SCRIPT = "https://raw.github.com/mxcl/homebrew/go"
  TEARDOWN_SCRIPT = "https://gist.github.com/mxcl/1173223/raw/a833ba44e7be8428d877e58640720ff43c59dbad/uninstall_homebrew.sh"

  def_delegator :@config, :brews

  def setup
    executor.start_section "Homebrew"
    # Feels wrong to call out to the terminal to start up a new Ruby oO
    executor.execute_interactive "Install", "ruby -e \"$(curl -fsSL #{INSTALL_SCRIPT})\""
  end

  def cleanup
    executor.start_section "Homebrew"
    executor.execute "Clean Up", "brew cleanup"
  end

  def teardown
    executor.start_section "Homebrew"
    executor.execute "Teardown", "\\curl -L #{TEARDOWN_SCRIPT} | bash -s"
  end

  def update
    executor.start_section "Homebrew"
    executor.execute "Updating Homebrew", "brew update"
    outdated_packages = outdated
    if outdated_packages == 0
      executor.info "Brews", "All up to date"
    else
      outdated_packages.each do |package|
        executor.execute "Upgrade #{package}", "brew upgrade #{package}"
      end
    end
  end

  def install
    executor.start_section "Homebrew"
    brews.each do |brew|
      if brew.class == String
        install_package brew
      else
        name = brew.keys.first
        options = brew[name]
        install_package name, options
      end
    end
  end

  private

  def outdated
    `brew outdated`.split("\n")
  end

  def install_package(name, options = [])
    executor.execute "Installing #{name}", "brew install #{name} #{options.join}" do |output|
      raise TaskSkipped.new("Already installed") if output.include? "already installed"
    end
  end
end

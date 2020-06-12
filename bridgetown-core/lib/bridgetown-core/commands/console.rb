# frozen_string_literal: true

module Bridgetown
  module Commands
    class Console < Thor::Group
      extend Summarizable
      include ConfigurationOverridable

      Registrations.register do
        register(Console, "console", "console", Console.summary)
      end

      def self.banner
        "bridgetown console [options]"
      end
      summary "Invoke an IRB console with the site loaded"

      class_option :config,
                   type: :array,
                   banner: "FILE1 FILE2",
                   desc: "Custom configuration file(s)"
      class_option :blank,
                   type: :boolean,
                   desc: "Skip reading content and running generators before opening console"

      def console
        require "irb"
        require "awesome_print"

        Bridgetown.logger.info "Starting:", "Bridgetown v#{Bridgetown::VERSION.magenta}" \
                                    " (codename \"#{Bridgetown::CODE_NAME.yellow}\")" \
                                    " console…"
        Bridgetown.logger.info "Environment:", Bridgetown.environment.cyan
        site = Bridgetown::Site.new(configuration_with_overrides(options))

        unless options[:blank]
          site.reset
          Bridgetown.logger.info "Reading files..."
          site.read
          Bridgetown.logger.info "", "done!"
          Bridgetown.logger.info "Running generators..."
          site.generate
          Bridgetown.logger.info "", "done!"
        end

        $BRIDGETOWN_SITE = site
        IRB.setup(nil)
        workspace = IRB::WorkSpace.new
        irb = IRB::Irb.new(workspace)
        IRB.conf[:MAIN_CONTEXT] = irb.context
        eval("site = $BRIDGETOWN_SITE", workspace.binding, __FILE__, __LINE__)
        Bridgetown.logger.info "Console:", "Now loaded as " + "site".cyan + " variable."

        trap("SIGINT") do
          irb.signal_handle
        end

        begin
          catch(:IRB_EXIT) do
            AwesomePrint.defaults = {
              indent: 2,
            }
            AwesomePrint.irb!
            irb.eval_input
          end
        end
      end
    end
  end
end
